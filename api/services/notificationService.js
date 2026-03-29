import admin from "../config/firebase.js";
import NotificationPreference from "../models/NotificationPreference.js";
const sendNotification = async (tokens, title, body, data = {}) => {
  if (!tokens.length) return;

  const message = {
    notification: { title, body },
    data,
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ ${response.successCount} notifications envoyées`);
    console.log(`❌ ${response.failureCount} échecs`);
    // ← Ajoutez ça
    response.responses.forEach((resp, i) => {
      if (!resp.success) {
        console.error(`❌ Erreur token ${i}:`, resp.error);
      } else {
        console.log(`✅ Token ${i} envoyé avec succès`);
      }
    });
    return response;
  } catch (error) {
    console.error("❌ Erreur envoi notification:", error);
  }
};

const notifyEventReminder = async (event, daysBefore) => {
  // Trouver tous les users concernés par cet événement
  const concernedUserIds = getConcernedUsers(event);

  const preferences = await NotificationPreference.find({
    user: { $in: concernedUserIds },
    enabled: true,
    [`preferences.${daysBefore === 7 ? "weekBefore" : "dayBefore"}`]: true,
  });

  const tokens = preferences
    .flatMap((pref) => pref.fcmTokens.map((t) => t.token))
    .filter(Boolean);

  const eventTypeLabel =
    {
      creathon: "Créathon",
      formation: "Formation",
      bootcamp: "Bootcamp",
      mentorat: "Mentorat",
    }[event.type] || "Événement";

  await sendNotification(
    tokens,
    `Rappel — ${eventTypeLabel} dans ${daysBefore} jour${daysBefore > 1 ? "s" : ""}`,
    `${event.title} commence le ${new Date(event.startDate).toLocaleDateString("fr-FR")}`,
    { eventId: event._id.toString(), eventType: event.type },
  );
};

const notifyReschedule = async (event, oldDate) => {
  const concernedUserIds = getConcernedUsers(event);

  const preferences = await NotificationPreference.find({
    user: { $in: concernedUserIds },
    enabled: true,
  });

  const tokens = preferences
    .flatMap((pref) => pref.fcmTokens.map((t) => t.token))
    .filter(Boolean);

  await sendNotification(
    tokens,
    `📅 Date modifiée — ${event.title}`,
    `Nouvelle date : ${new Date(event.startDate).toLocaleDateString("fr-FR")}`,
    { eventId: event._id.toString(), eventType: event.type },
  );
};

// Retourne les IDs des users concernés selon le type d'événement
const getConcernedUsers = (event) => {
  const users = [];

  // Créathon
  if (event.coordinators?.componentCoordinator)
    users.push(event.coordinators.componentCoordinator);
  if (event.coordinators?.generalCoordinator)
    users.push(event.coordinators.generalCoordinator);

  // Training / Bootcamp / Mentorat
  if (event.componentCoordinator) users.push(event.componentCoordinator);
  if (event.incubationCoordinators) users.push(...event.incubationCoordinators);
  if (event.trainers) users.push(...event.trainers);

  // Participants communs
  if (event.participants) users.push(...event.participants);
  if (event.mentors?.assigned) users.push(...event.mentors.assigned);
  if (event.jury?.assigned) users.push(...event.jury.assigned);

  return users.filter(Boolean);
};

export const notifyNewEvent = async (event) => {
  console.log("🔔 notifyNewEvent appelé pour:", event.title);
  const concernedUserIds = getConcernedUsers(event);
  console.log("👥 Users concernés:", concernedUserIds);
  const preferences = await NotificationPreference.find({
    user: { $in: concernedUserIds },
    enabled: true,
  });

  console.log("📱 Préférences trouvées:", preferences.length);
  console.log(
    "📱 Tokens:",
    preferences.flatMap((p) => p.fcmTokens),
  );

  console.log("📱 Tous les docs NotificationPreference:");
  const allPrefs = await NotificationPreference.find({});
  allPrefs.forEach((p) =>
    console.log("  -", p.user?.toString(), "tokens:", p.fcmTokens?.length),
  );

  const tokens = preferences
    .flatMap((pref) => pref.fcmTokens.map((t) => t.token))
    .filter(Boolean);

  if (!tokens.length) return;

  const eventTypeLabel =
    {
      creathon: "Créathon",
      formation: "Formation",
      bootcamp: "Bootcamp",
      mentorat: "Mentorat",
    }[event.type] || "Événement";

  await sendNotification(
    tokens,
    `🎉 Nouvel événement — ${eventTypeLabel}`,
    `${event.title} a été créé`,
    { eventId: event._id.toString(), eventType: event.type },
  );
};
export { notifyEventReminder, notifyReschedule };
