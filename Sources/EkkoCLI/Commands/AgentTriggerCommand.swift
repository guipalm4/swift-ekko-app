import ArgumentParser
import EkkoCore

struct AgentTriggerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent-trigger",
        abstract: "Internal: trigger the backup agent (invoked by launchd)."
    )

    func run() throws {
        let logger = EkkoLogger()
        logger.log("agent triggered", level: .info, category: "agent")
    }
}
