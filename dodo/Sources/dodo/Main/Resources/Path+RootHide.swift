import Foundation
import dodoC

extension String {
    var dodoRootPath: String {
        DodoPreferenceRootPath(self)
    }
}
