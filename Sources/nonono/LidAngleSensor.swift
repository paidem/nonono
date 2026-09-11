import Foundation
import IOKit
import IOKit.hid

/// Reads the MacBook hinge angle from the undocumented Apple HID sensor
/// (VID 0x05AC, PID 0x8104, usage page 0x20 Sensors, usage 0x8A).
/// Feature report 1 is {reportID, angleLo, angleHi}, little-endian degrees.
///
/// The manager matches only that one interface and is never opened: opening a
/// manager with a nil match would open every HID device, keyboards included,
/// which is what triggers the Input Monitoring permission prompt.
final class LidAngleSensor {
    private let manager: IOHIDManager
    private let device: IOHIDDevice

    init?() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Int] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDPrimaryUsagePageKey: 0x20,
            kIOHIDPrimaryUsageKey: 0x8A,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              let device = devices.first else { return nil }
        guard IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            return nil
        }
        self.manager = manager
        self.device = device
    }

    func read() -> Int? {
        var buffer = [UInt8](repeating: 0, count: 8)
        var length: CFIndex = buffer.count
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, &buffer, &length)
        guard result == kIOReturnSuccess, length >= 3 else { return nil }
        return Int(buffer[1]) | (Int(buffer[2]) << 8)
    }
}
