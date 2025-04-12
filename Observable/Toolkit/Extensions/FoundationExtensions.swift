//
//  Extensions.swift
//  Insights
//
//  Created by whoog on 2024/5/26.
//

import Foundation

/// MARK: Abound System Librarys

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return self.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
}

extension Date {
    init(year: Int, month: Int, day: Int = 1, hour: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self = Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minutes, second: seconds)) ?? Date()
    }
    
    /// 年份
    var year: Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: self)
    }
    
    /// 月份
    var month: Int {
        let calendar = Calendar.current
        return calendar.component(.month, from: self)
    }
    
    /// 日
    var day: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: self)
    }
    
    func formatted(_ format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    var yyyy: String { formatted("yyyy") }
    
    var yyyyMM: String { formatted("yyyyMM") }
    
    var yyyyMMdd: String { formatted("yyyyMMdd") }
    
    func plusYear(_ value: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: value, to: self)!
    }
    
    func plusMonth(_ value: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: value, to: self)!
    }
    
    func plusDay(_ value: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: value, to: self)!
    }
    
    func plusHour(_ value: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: value, to: self)!
    }
    
    func plusMintes(_ value: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: value, to: self)!
    }
    
    func plusSeconds(_ value: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: value, to: self)!
    }
    
    static func betweenDays(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
    
    func endOfDay() -> Date {
        Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(from: DateComponents(year: self.year, month: self.month, day: self.day + 1))!)!
    }
    
    func endOfMonth() -> Date {
        Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(from: DateComponents(year: self.year, month: self.month + 1))!)!
    }
    
    func endOfYear() -> Date {
        Calendar.current.date(byAdding: .second, value: -1, to: Calendar.current.date(from: DateComponents(year: self.year + 1))!)!
    }
    
    /// MARK: 小众的
    
    func formatDateToCustomString(_ complete: Bool = false) -> String {
        let currentYear = Calendar.current.component(.year, from: Date()) // 当前年份
        let dateYear = Calendar.current.component(.year, from: self) // 传入日期的年份
        
        let formatter = DateFormatter()
        if !complete && currentYear == dateYear {
            // 如果是今年，只显示 "M月d日"
            formatter.dateFormat = "M月d日"
        } else {
            // 如果不是今年，显示 "yy年M月d日"
            formatter.dateFormat = "yy年M月d日"
        }
        
        return formatter.string(from: self)
    }
}

extension Double {
    func formatToK() -> String {
        if abs(self) < 1000 {
            return String(format: "%.0f", self) // 小于 1000 显示原值
        } else if abs(self) < 10_000 {
            let valueInK = self / 1000
            let formattedValue = String(format: valueInK == floor(valueInK) ? "%.0f" : "%.1f", valueInK)
            return "\(formattedValue)k"
        } else {
            let valueInW = self / 10_000
            let formattedValue = String(format: valueInW == floor(valueInW) ? "%.0f" : "%.1f", valueInW)
            return "\(formattedValue)w"
        }
    }
}

struct Pair<K: Any, V: Any> {
    var key: K
    var val: V
}
