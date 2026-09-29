//
//  Analytics.swift
//  Kitapi
//
//  Created by Suneel on 07/08/26.
//

import Foundation

struct AnalyticsResponse: Codable {
    let success: Bool
    let data: AnalyticsData
}

struct AnalyticsData: Codable {
    let childInfo: Child
    let coinStats: CoinStatistics?
    let chorePercentages: ChorePercentage?
    let goalPercentages: GoalPercentage?
    let choreCounts: ChoreCount?
    let goalCounts: GoalCount?
    let currentGoals: [GoalData]
    let periodChores: PeriodChores?
    let periodAnalytics: PeriodAnalytics?
    let recentTransactions: [RecentTransaction]
    let generatedAt: String
}
struct CoinStatistics: Codable {
    let currentBalance, totalEarned, totalSpent: Int
}

struct ChorePercentage: Codable {
    let completed, rejected: Double?
    let pending, overdue, upcoming: Double?
    let total: Double
}

struct GoalPercentage: Codable {
    let completed, rejected, pending, total: Double?
}

struct ChoreCount: Codable {
    let completed, rejected: Int?
    let pending, overdue, upcoming: Int?
    let total: Int
}

struct GoalCount: Codable {
    let completed, rejected, pending, total: Int?
}

struct GoalProgressDetails: Codable {
    let completedTasks: Int?
    let totalTasks: Int?
    let tasksText: String?
    
    let currentCoins: Int?
    let targetCoins: Int?
    let coinsText: String?
    
    let percentage: Int?
}

struct PeriodChores: Codable {
    let period: Period
    let startDate, endDate: String?
    let filters: AppliedFilters
    let pagination: PagesData
    let chores: [TaskData]
}

struct PagesData: Codable {
    let currentPage, totalPages, totalCount, pageSize: Int
    let hasNextPage, hasPreviousPage: Bool
}

struct PeriodAnalytics: Codable {
    let period: Period?
    let startDate, endDate: String?
    let completed: [CompletedPeriod]
}

struct CompletedPeriod: Codable {
    let period: String
    let count: Int
}

struct RecentTransaction: Codable {
    let id: String
    let amount: Int?
    let type, description, createdAt: String?
    let task: TaskInfo?
    let currentBalance: Int?
}

struct TaskInfo: Codable {
    let id, title: String
}

enum Period: String, Codable {
    case day
    case week
    case month
    case all
}
