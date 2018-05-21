
import Foundation
import CoreBluetooth

struct BtClient {

    static let shared = SharedBtClient()
}


class SharedBtClient: NSObject {

    var centralManager: CBCentralManager?
    let uuid = CBUUID(string: "0FFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFF0")
    var peripherals: [CBPeripheral] = []

    func start() {

        centralManager = CBCentralManager()
        centralManager?.delegate = self
    }

    func stop() {

        stopSearchingForService()
    }
}

extension SharedBtClient {

    fileprivate func searchAndWriteToService() {
        centralManager?.scanForPeripherals(withServices: [uuid], options: nil)
    }

    fileprivate func stopSearchingForService() {

        centralManager?.stopScan()
    }
}

extension SharedBtClient: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        print(String(describing: centralManager?.state.rawValue))
        searchAndWriteToService()
    }


    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        peripherals.append(peripheral)

        centralManager?.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        let properties = CBCharacteristicProperties.authenticatedSignedWrites
//        let permissions: CBAttributePermissions = [.readable, .writeable]
//        let characteristic = CBMutableCharacteristic(type: uuid, properties: properties, value: nil, permissions: permissions)

        peripheral.delegate = self
        peripheral.discoverServices([uuid])
    }
}

extension SharedBtClient: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        guard let services = peripheral.services,
            services.count > 0 else {
            print("Empty services")
            return
        }

        print(services)


        for targetService in services {
            if targetService.uuid == uuid {


                var targetCharacteristics: [CBUUID] = []
                for characteristic in targetService.characteristics! {
                    targetCharacteristics.append(characteristic.uuid)
                }

                peripheral.discoverCharacteristics(targetCharacteristics, for: services.first!)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics,
            characteristics.count > 0 else {
            print("empty charaterstics")
            return
        }
        peripheral.writeValue(Data(bytes:[0xEE, 0xEE]), for: characteristics.first!, type: CBCharacteristicWriteType.withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print(descriptor)
    }
}

