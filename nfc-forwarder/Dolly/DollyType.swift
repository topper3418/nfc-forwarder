enum DollyType: String {
    case none = "No Type"
    case regular = "Regular"
    case cutoutLH = "Cutout Longside LH"
    case cutoutRH = "Cutout Longside RH"
    case cutoutSS = "Cutout Shortside"
    
    // Convert from integer ID to DollyType
    static func from(id: Int) -> DollyType? {
        switch id {
        case 0: return DollyType.none
        case 1: return .regular
        case 2: return .cutoutLH
        case 3: return .cutoutRH
        case 4: return .cutoutSS
        default: return nil
        }
    }
    
    // Convert from string to DollyType
    static func from(string: String) -> DollyType? {
        return DollyType(rawValue: string)
    }
    
    // Convert to string (same as rawValue)
    var string: String {
        return self.rawValue
    }
    
    // Convert to integer ID
    var integer: Int {
        switch self {
        case .regular: return 1
        case .cutoutLH: return 2
        case .cutoutRH: return 3
        case .cutoutSS: return 4
        case .none: return 0
        }
    }
    
}
