export const NotificationPlugin = async ({ $ }) => {
  const notify = (title, message, sound = "Glass") =>
    $`osascript -e ${`display notification "${message}" with title "${title}" sound name "${sound}"`}`

  return {
    "permission.asked": async () => {
      await notify("opencode", "Permission requested", "Funk")
    },
    "session.idle": async () => {
      await notify("opencode", "Session idle — ready for input", "Glass")
    },
  }
}
