import Foundation
import DodoC

extension String {
    /// Converts a jailbreak-root path to the current RootHide rootfs path.
    /// RootHide randomizes jbroot, so a fixed /var/jb prefix is not valid.
    var dodoRootPath: String {
        DodoRootPath(self)
    }
}
