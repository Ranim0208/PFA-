import cron from "node-cron";
import Creathon from "../models/Creathon.js";
import Training from "../models/Training.js";
import { notifyEventReminder } from "../services/notificationService.js";

const startNotificationScheduler = () => {
  cron.schedule("0 9 * * *", async () => {
    console.log("🔔 Vérification des rappels d'événements...");

    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const in1Day = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);
    const formatDate = (date) => date.toISOString().split("T")[0];

    try {
      // ─── CRÉATHONS ───────────────────────────────────────────
      const creathonsIn7Days = await Creathon.find({
        "dates.startDate": {
          $gte: new Date(formatDate(in7Days)),
          $lt: new Date(formatDate(in7Days) + "T23:59:59"),
        },
        status: { $in: ["planned", "draft"] },
      }).populate(
        "coordinators.componentCoordinator coordinators.generalCoordinator",
      );

      for (const event of creathonsIn7Days) {
        await notifyEventReminder({ ...event.toObject(), type: "creathon" }, 7);
      }

      const creathonsIn1Day = await Creathon.find({
        "dates.startDate": {
          $gte: new Date(formatDate(in1Day)),
          $lt: new Date(formatDate(in1Day) + "T23:59:59"),
        },
        status: { $in: ["planned", "draft"] },
      }).populate(
        "coordinators.componentCoordinator coordinators.generalCoordinator",
      );

      for (const event of creathonsIn1Day) {
        await notifyEventReminder({ ...event.toObject(), type: "creathon" }, 1);
      }

      // ─── TRAININGS / BOOTCAMPS / MENTORATS ───────────────────
      const trainingsIn7Days = await Training.find({
        startDate: {
          $gte: new Date(formatDate(in7Days)),
          $lt: new Date(formatDate(in7Days) + "T23:59:59"),
        },
        status: "approved",
      }).populate("componentCoordinator incubationCoordinators trainers");

      for (const event of trainingsIn7Days) {
        await notifyEventReminder({ ...event.toObject(), type: event.type }, 7);
      }

      const trainingsIn1Day = await Training.find({
        startDate: {
          $gte: new Date(formatDate(in1Day)),
          $lt: new Date(formatDate(in1Day) + "T23:59:59"),
        },
        status: "approved",
      }).populate("componentCoordinator incubationCoordinators trainers");

      for (const event of trainingsIn1Day) {
        await notifyEventReminder({ ...event.toObject(), type: event.type }, 1);
      }

      console.log("✅ Rappels traités");
    } catch (error) {
      console.error("❌ Erreur scheduler:", error);
    }
  });

  console.log("⏰ Notification scheduler démarré");
};

export default startNotificationScheduler;
