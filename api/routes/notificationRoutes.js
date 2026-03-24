import express from "express";
import NotificationPreference from "../models/NotificationPreference.js";
import { notifyReschedule } from "../services/notificationService.js";
const router = express.Router();

// Enregistrer / mettre à jour le token FCM d'un appareil
router.post("/register-token", async (req, res) => {
  const { userId, token, device } = req.body;
  try {
    let pref = await NotificationPreference.findOne({ user: userId });
    if (!pref) {
      pref = new NotificationPreference({ user: userId, fcmTokens: [] });
    }
    // Éviter les doublons
    const exists = pref.fcmTokens.find((t) => t.token === token);
    if (!exists) {
      pref.fcmTokens.push({ token, device });
    }
    await pref.save();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Mettre à jour les préférences
router.put("/preferences/:userId", async (req, res) => {
  const { weekBefore, dayBefore, enabled } = req.body;
  try {
    const pref = await NotificationPreference.findOneAndUpdate(
      { user: req.params.userId },
      { preferences: { weekBefore, dayBefore }, enabled },
      { new: true, upsert: true },
    );
    res.json({ success: true, pref });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Récupérer les préférences
router.get("/preferences/:userId", async (req, res) => {
  try {
    const pref = await NotificationPreference.findOne({
      user: req.params.userId,
    });
    res.json(
      pref || {
        preferences: { weekBefore: true, dayBefore: true },
        enabled: true,
      },
    );
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
export default router;
