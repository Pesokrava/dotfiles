import { execFile } from "node:child_process"

const notify = (message, sound) =>
  execFile("osascript", ["-e", `display notification "${message}" with title "opencode" sound name "${sound}"`], () => {})

export default {
  id: "martin.notification",
  setup(ctx) {
    // ponytail: macOS only; the Linux workspace has no notification center.
    if (process.platform !== "darwin") return
    const controller = new AbortController()
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type === "permission.asked") notify("Permission requested", "Funk")
        if (event.type === "session.idle") notify("Session idle — ready for input", "Glass")
      }
    })().catch(() => {})
    return () => controller.abort()
  },
}
