//
//  ExtensibleHintsExample.swift
//  SixLayerFramework
//
//  Example of how framework users can extend the hints system
//

import SwiftUI

// MARK: - Example: E-commerce Product Catalog Hints

/// Custom hint for e-commerce product catalogs
public class EcommerceProductHint: CustomHint {
    init(
        category: String,
        showPricing: Bool = true,
        showReviews: Bool = true,
        layoutStyle: String = "grid",
        showWishlist: Bool = true,
        quickViewEnabled: Bool = true
    ) {
        super.init(
            hintType: "ecommerce.product.\(category)",
            priority: .high,
            overridesDefault: false,
            customData: [
                "category": category,
                "showPricing": showPricing,
                "showReviews": showReviews,
                "layoutStyle": layoutStyle,
                "showWishlist": showWishlist,
                "quickViewEnabled": quickViewEnabled,
                "recommendedColumns": 3,
                "filteringEnabled": true,
                "sortingEnabled": true,
                "searchEnabled": true
            ]
        )
    }
}

// MARK: - Example: Social Media Feed Hints

/// Custom hint for social media feeds
public class SocialFeedHint: CustomHint {
    init(
        contentType: String,
        showInteractions: Bool = true,
        autoPlay: Bool = false,
        infiniteScroll: Bool = true,
        pullToRefresh: Bool = true
    ) {
        super.init(
            hintType: "social.feed.\(contentType)",
            priority: .normal,
            overridesDefault: false,
            customData: [
                "contentType": contentType,
                "showInteractions": showInteractions,
                "autoPlay": autoPlay,
                "infiniteScroll": infiniteScroll,
                "pullToRefresh": pullToRefresh,
                "showUserAvatars": true,
                "showTimestamps": true,
                "showEngagementMetrics": true
            ]
        )
    }
}

// MARK: - Example: Financial Dashboard Hints

/// Custom hint for financial dashboards
public class FinancialDashboardHint: CustomHint {
    init(
        timeRange: String,
        showCharts: Bool = true,
        refreshRate: Int = 60,
        realTimeUpdates: Bool = true,
        exportEnabled: Bool = true
    ) {
        super.init(
            hintType: "financial.dashboard.\(timeRange)",
            priority: .critical,
            overridesDefault: true, // Financial data needs real-time updates
            customData: [
                "timeRange": timeRange,
                "showCharts": showCharts,
                "refreshRate": refreshRate,
                "realTimeUpdates": realTimeUpdates,
                "exportEnabled": exportEnabled,
                "drillDownEnabled": true,
                "showAlerts": true,
                "customizableWidgets": true
            ]
        )
    }
}

// MARK: - Example: Blog Post List Hints

/// Custom hint for blog post lists
public class BlogPostHint: CustomHint {
    init(
        showExcerpts: Bool = true,
        showAuthor: Bool = true,
        showDate: Bool = true,
        showReadMore: Bool = true,
        estimatedReadingTime: Bool = true
    ) {
        super.init(
            hintType: "blog.posts",
            priority: .normal,
            overridesDefault: false,
            customData: [
                "showExcerpts": showExcerpts,
                "showAuthor": showAuthor,
                "showDate": showDate,
                "showReadMore": showReadMore,
                "estimatedReadingTime": estimatedReadingTime,
                "layoutStyle": "list",
                "recommendedColumns": 1,
                "showCategories": true,
                "showTags": true
            ]
        )
    }
}

// MARK: - Example: Photo Gallery Hints

/// Custom hint for photo galleries
public class PhotoGalleryHint: CustomHint {
    init(
        showMetadata: Bool = true,
        allowFullscreen: Bool = true,
        gridStyle: String = "masonry",
        lazyLoading: Bool = true,
        zoomEnabled: Bool = true
    ) {
        super.init(
            hintType: "photo.gallery",
            priority: .high,
            overridesDefault: false,
            customData: [
                "showMetadata": showMetadata,
                "allowFullscreen": allowFullscreen,
                "gridStyle": gridStyle,
                "lazyLoading": lazyLoading,
                "zoomEnabled": zoomEnabled,
                "shareEnabled": true,
                "downloadEnabled": true,
                "slideshowEnabled": true
            ]
        )
    }
}

// MARK: - Example Usage Functions

/// Example functions showing how to use custom hints with the framework
public struct ExtensibleHintsExamples {
    
    /// Example: Present e-commerce products with custom hints
    @MainActor
        static func presentEcommerceProducts(
        products: [GenericItem],
        category: String = "electronics"
    ) -> some View {
        let hints = EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [
                EcommerceProductHint(
                    category: category,
                    showPricing: true,
                    showReviews: true,
                    layoutStyle: "grid",
                    showWishlist: true,
                    quickViewEnabled: true
                )
            ]
        )
        
        return platformPresentItemCollection_L1(
            items: products,
            hints: hints
        )
    }
    
    /// Example: Present social media feed with custom hints
    @MainActor
        static func presentSocialFeed(
        posts: [GenericItem],
        contentType: String = "general"
    ) -> some View {
        let hints = EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [
                SocialFeedHint(
                    contentType: contentType,
                    showInteractions: true,
                    autoPlay: false,
                    infiniteScroll: true,
                    pullToRefresh: true
                )
            ]
        )
        
        return platformPresentItemCollection_L1(
            items: posts,
            hints: hints
        )
    }
    
    /// Example: Present financial dashboard with custom hints
    @MainActor
        static func presentFinancialDashboard(
        data: [GenericNumericData],
        timeRange: String = "daily"
    ) -> some View {
        let hints = EnhancedPresentationHints(
            dataType: .numeric,
            presentationPreference: .chart,
            complexity: .complex,
            context: .dashboard,
            extensibleHints: [
                FinancialDashboardHint(
                    timeRange: timeRange,
                    showCharts: true,
                    refreshRate: 30, // 30-second refresh for financial data
                    realTimeUpdates: true,
                    exportEnabled: true
                )
            ]
        )
        
        return platformPresentNumericData_L1(
            data: data,
            hints: hints
        )
    }
    
    /// Example: Present blog posts with custom hints
    @MainActor
        static func presentBlogPosts(
        posts: [GenericItem],
        showExcerpts: Bool = true,
        showAuthor: Bool = true
    ) -> some View {
        let hints = EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .list,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [
                BlogPostHint(
                    showExcerpts: showExcerpts,
                    showAuthor: showAuthor,
                    showDate: true,
                    showReadMore: true,
                    estimatedReadingTime: true
                )
            ]
        )
        
        return platformPresentItemCollection_L1(
            items: posts,
            hints: hints
        )
    }
    
    /// Example: Present photo gallery with custom hints
    @MainActor
        static func presentPhotoGallery(
        photos: [GenericMediaItem],
        showMetadata: Bool = true,
        allowFullscreen: Bool = true
    ) -> some View {
        let hints = EnhancedPresentationHints(
            dataType: .media,
            presentationPreference: .masonry,
            complexity: .moderate,
            context: .browse,
            extensibleHints: [
                PhotoGalleryHint(
                    showMetadata: showMetadata,
                    allowFullscreen: allowFullscreen,
                    gridStyle: "masonry",
                    lazyLoading: true,
                    zoomEnabled: true
                )
            ]
        )
        
        return platformPresentMediaData_L1(
            media: photos,
            hints: hints
        )
    }
}

// MARK: - Example: How Framework Users Would Use This

/*
 
 // Framework users would use it like this:
 
 struct MyAppView: View {
     let products: [Product]
     let posts: [Post]
     let financialData: [FinancialData]
     
     var body: some View {
         VStack {
             // E-commerce products with custom hints
             ExtensibleHintsExamples.presentEcommerceProducts(
                 products: products,
                 category: "electronics"
             )
             
             // Social media feed with custom hints
             ExtensibleHintsExamples.presentSocialFeed(
                 posts: posts,
                 contentType: "general"
             )
             
             // Financial dashboard with custom hints
             ExtensibleHintsExamples.presentFinancialDashboard(
                 data: financialData,
                 timeRange: "daily"
             )
         }
     }
 }
 
 // Or create their own custom hints:
 
 class MyCustomHint: CustomHint {
     init(mySetting: Bool = true) {
         super.init(
             hintType: "myapp.custom",
             priority: .high,
             overridesDefault: false,
             customData: [
                 "mySetting": mySetting,
                 "customBehavior": "special"
             ]
         )
     }
 }
 
 let myHints = EnhancedPresentationHints(
     dataType: .collection,
     presentationPreference: .cards,
     complexity: .moderate,
     context: .dashboard,
     extensibleHints: [MyCustomHint(mySetting: true)]
 )
 
 platformPresentItemCollection_L1(
     items: myItems,
     hints: myHints
 )
 
 */
