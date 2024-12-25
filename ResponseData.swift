// ResponseData.swift
import Foundation

struct ResponseData: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let selectedText: String
    let option: WritingOption
}
