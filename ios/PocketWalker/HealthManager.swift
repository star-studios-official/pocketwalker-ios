import Foundation
import HealthKit

/// Manages HealthKit integration for step counting
class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    @Published var isEnabled = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    /// Check if HealthKit is available
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization to read step count data
    func requestAuthorization() {
        guard isHealthKitAvailable else {
            print("HealthKit not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.authorizationStatus = .sharingAuthorized
                    self?.isEnabled = true
                    print("HealthKit authorization granted")
                } else {
                    self?.authorizationStatus = .sharingDenied
                    print("HealthKit authorization denied: \(error?.localizedDescription ?? "unknown")")
                }
            }
        }
    }
    
    /// Fetch today's total step count from HealthKit
    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard isHealthKitAvailable else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Fetch step count for a specific date range
    func fetchSteps(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Start observing step count changes (for live updates)
    func startObservingStepChanges(handler: @escaping (Int) -> Void) {
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, _ in
            self?.fetchTodaySteps(completion: handler)
            completionHandler()
        }
        
        healthStore.execute(query)
    }
    
    /// Enable background delivery for step count updates
    func enableBackgroundDelivery() {
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .hourly) { success, error in
            if success {
                print("Background delivery enabled for step count")
            } else {
                print("Failed to enable background delivery: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
}
