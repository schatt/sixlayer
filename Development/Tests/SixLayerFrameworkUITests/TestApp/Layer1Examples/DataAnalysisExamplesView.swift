//
//  DataAnalysisExamplesView.swift
//  SixLayerFrameworkUITests
//
//  Examples of Layer 1 data analysis functions
//  Issue #166
//

import SwiftUI
import SixLayerFramework
import TabularData

struct Layer1DataAnalysisExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 24) {
            ExampleSection(title: "DataFrame Analysis") {
                DataFrameAnalysisExamples()
            }
            
            ExampleSection(title: "Compare DataFrames") {
                DataFrameComparisonExamples()
            }
            
            ExampleSection(title: "Assess Data Quality") {
                DataQualityAssessmentExamples()
            }
        }
        .padding()
        .platformFrame()
    }
}

struct DataFrameAnalysisExamples: View {
    // Create a sample DataFrame for testing
    private var sampleDataFrame: DataFrame {
        var frame = DataFrame()
        frame.append(column: Column(name: "Name", contents: ["Alice", "Bob", "Charlie"]))
        frame.append(column: Column(name: "Age", contents: [25, 30, 35]))
        frame.append(column: Column(name: "Score", contents: [85.5, 92.0, 78.5]))
        return frame
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("DataFrame Analysis")
                .font(.headline)
            
            platformAnalyzeDataFrame_L1(
                dataFrame: sampleDataFrame,
                hints: DataFrameAnalysisHints()
            )
            .frame(height: 400)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct DataFrameComparisonExamples: View {
    private var sampleDataFrame1: DataFrame {
        var frame = DataFrame()
        frame.append(column: Column(name: "Name", contents: ["Alice", "Bob"]))
        frame.append(column: Column(name: "Age", contents: [25, 30]))
        return frame
    }
    
    private var sampleDataFrame2: DataFrame {
        var frame = DataFrame()
        frame.append(column: Column(name: "Name", contents: ["Alice", "Bob", "Charlie"]))
        frame.append(column: Column(name: "Age", contents: [25, 30, 35]))
        return frame
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("DataFrame Comparison")
                .font(.headline)
            
            platformCompareDataFrames_L1(
                dataFrames: [sampleDataFrame1, sampleDataFrame2],
                hints: DataFrameAnalysisHints()
            )
            .frame(height: 400)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

struct DataQualityAssessmentExamples: View {
    private var sampleDataFrame: DataFrame {
        var frame = DataFrame()
        frame.append(column: Column(name: "Name", contents: ["Alice", "Bob", "Charlie"]))
        frame.append(column: Column(name: "Age", contents: [25, 30, 35]))
        frame.append(column: Column(name: "Score", contents: [85.5, 92.0, 78.5]))
        return frame
    }
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Data Quality Assessment")
                .font(.headline)
            
            platformAssessDataQuality_L1(
                dataFrame: sampleDataFrame,
                hints: DataFrameAnalysisHints()
            )
            .frame(height: 400)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Helper Views

private struct ExampleSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        platformVStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
            
            content()
        }
    }
}
