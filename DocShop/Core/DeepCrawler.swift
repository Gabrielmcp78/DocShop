import Foundation
import SwiftSoup
import Combine

@MainActor
class DeepCrawler: ObservableObject {
    static let shared = DeepCrawler()
    
    @Published var isCrawling = false
    @Published var crawlProgress: Double = 0.0
    @Published var currentCrawlStatus = "Ready"
    @Published var discoveredLinks: [CrawlLink] = []
    @Published var crawledPages: Set<String> = []
    @Published var crawlQueue: [CrawlTask] = []
    
    private let config = DocumentProcessorConfig.shared
    private let processor = DocumentProcessor.shared
    private let security = SecurityManager.shared
    private let logger = DocumentLogger.shared
    private let aiAnalyzer = AIDocumentAnalyzer.shared
    
    private var crawlSession: CrawlSession?
    private let crawlQueue_internal = DispatchQueue(label: "deep.crawler", qos: .userInitiated)
    
    private init() {}
    
    func startDeepCrawl(from rootURL: URL, maxDepth: Int? = nil) async {
        guard !isCrawling else {
            logger.warning("Deep crawl already in progress")
            return
        }
        
        guard config.enableDeepCrawling else {
            logger.info("Deep crawling is disabled in configuration")
            return
        }
        
        isCrawling = true
        currentCrawlStatus = "Initializing deep crawl..."
        crawlProgress = 0.0
        
        let session = CrawlSession(
            rootURL: rootURL,
            maxDepth: maxDepth ?? config.maxCrawlDepth,
            maxPagesPerDomain: config.maxPagesPerDomain,
            crawlDelay: config.crawlDelay,
            followExternalLinks: config.followExternalLinks
        )
        
        crawlSession = session
        
        defer {
            isCrawling = false
            crawlSession = nil
            currentCrawlStatus = "Crawl completed"
        }
        
        do {
            try await performDeepCrawl(session: session)
        } catch {
            logger.error("Deep crawl failed: \(error)")
            currentCrawlStatus = "Crawl failed: \(error.localizedDescription)"
        }
    }
    
    private func performDeepCrawl(session: CrawlSession) async throws {
        var visitedURLs: Set<String> = []
        var urlQueue: [(URL, Int)] = [(session.rootURL, 0)] // (URL, depth)
        var domainPageCounts: [String: Int] = [:]
        
        currentCrawlStatus = "Starting crawl from \(session.rootURL.host ?? "unknown")"
        
        while !urlQueue.isEmpty {
            let (currentURL, depth) = urlQueue.removeFirst()
            let urlString = currentURL.absoluteString
            
            // Skip if already visited
            if visitedURLs.contains(urlString) {
                continue
            }
            
            // Skip if depth exceeded
            if depth > session.maxDepth {
                continue
            }
            
            // Check domain page limit
            let domain = currentURL.host ?? ""
            let currentDomainCount = domainPageCounts[domain] ?? 0
            if currentDomainCount >= session.maxPagesPerDomain {
                logger.info("Skipping \(urlString) - domain page limit reached for \(domain)")
                continue
            }
            
            visitedURLs.insert(urlString)
            domainPageCounts[domain] = currentDomainCount + 1
            
            currentCrawlStatus = "Crawling: \(currentURL.lastPathComponent) (depth \(depth))"
            crawlProgress = Double(visitedURLs.count) / Double(min(visitedURLs.count + urlQueue.count, session.maxPagesPerDomain))
            
            do {
                // Process the current page
                _ = try await processor.importDocument(from: urlString)
                
                await MainActor.run {
                    crawledPages.insert(urlString)
                }
                
                // Extract links from the page for further crawling
                let extractedLinks = try await extractLinksFromPage(url: currentURL, depth: depth)
                
                // Use AI to identify the most relevant links if available
                var linksToProcess = extractedLinks
                if aiAnalyzer.isAIAvailable && extractedLinks.count > 10 {
                    currentCrawlStatus = "AI analyzing link relevance..."
                    
                    let linkUrls = extractedLinks.map { $0.url.absoluteString }
                    let relevantLinks = await aiAnalyzer.identifyRelevantLinks(
                        from: linkUrls,
                        documentContent: "", // We could fetch content here if needed
                        documentTitle: currentURL.lastPathComponent
                    )
                    
                    // Filter and prioritize based on AI analysis
                    let prioritizedLinks = extractedLinks.filter { link in
                        relevantLinks.contains { $0.url == link.url.absoluteString && $0.priority >= 6 }
                    }
                    
                    if !prioritizedLinks.isEmpty {
                        linksToProcess = prioritizedLinks
                        logger.info("AI filtered \(extractedLinks.count) links down to \(prioritizedLinks.count) relevant ones")
                    }
                }
                
                // Add valid links to the queue
                for link in linksToProcess {
                    if shouldCrawlLink(link, session: session, visitedURLs: visitedURLs) {
                        urlQueue.append((link.url, depth + 1))
                    }
                }
                
                await MainActor.run {
                    discoveredLinks.append(contentsOf: extractedLinks)
                }
                
                logger.info("Successfully crawled: \(urlString) (found \(extractedLinks.count) links)")
                
                // Respect crawl delay
                if session.crawlDelay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(session.crawlDelay * 1_000_000_000))
                }
                
            } catch {
                logger.warning("Failed to crawl \(urlString): \(error)")
                continue
            }
        }
        
        currentCrawlStatus = "Deep crawl completed - processed \(visitedURLs.count) pages"
        crawlProgress = 1.0
    }
    
    private func extractLinksFromPage(url: URL, depth: Int) async throws -> [CrawlLink] {
        // Fetch the page content
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw CrawlError.invalidContent
        }
        
        let doc = try SwiftSoup.parse(html)
        let linkElements = try doc.select("a[href]")
        
        var extractedLinks: [CrawlLink] = []
        
        for linkElement in linkElements {
            guard let href = try? linkElement.attr("href"),
                  !href.isEmpty else { continue }
            
            // Resolve relative URLs
            guard let resolvedURL = URL(string: href, relativeTo: url) else { continue }
            
            let linkText = try? linkElement.text()
            let linkTitle = try? linkElement.attr("title")
            
            let crawlLink = CrawlLink(
                url: resolvedURL,
                text: linkText ?? "",
                title: linkTitle ?? "",
                sourceURL: url,
                depth: depth + 1,
                linkType: determineLinkType(url: resolvedURL, sourceURL: url)
            )
            
            extractedLinks.append(crawlLink)
        }
        
        return extractedLinks
    }
    
    private func shouldCrawlLink(_ link: CrawlLink, session: CrawlSession, visitedURLs: Set<String>) -> Bool {
        let urlString = link.url.absoluteString
        
        // Skip if already visited
        if visitedURLs.contains(urlString) {
            return false
        }
        
        // Skip if depth would be exceeded
        if link.depth > session.maxDepth {
            return false
        }
        
        // Skip non-documentation links
        if !isDocumentationLink(link) {
            return false
        }
        
        // Check if external links are allowed
        if link.linkType == .external && !session.followExternalLinks {
            return false
        }
        
        // Security validation
        do {
            try security.validateURL(link.url)
        } catch {
            logger.warning("Skipping link due to security validation: \(urlString)")
            return false
        }
        
        return true
    }
    
    private func determineLinkType(url: URL, sourceURL: URL) -> LinkType {
        guard let sourceHost = sourceURL.host,
              let targetHost = url.host else {
            return .unknown
        }
        
        if sourceHost == targetHost {
            return .internal
        } else if targetHost.hasSuffix(sourceHost) || sourceHost.hasSuffix(targetHost) {
            return .subdomain
        } else {
            return .external
        }
    }
    
    private func isDocumentationLink(_ link: CrawlLink) -> Bool {
        let url = link.url
        let path = url.path.lowercased()
        let text = link.text.lowercased()
        
        // Skip obvious non-documentation links
        let skipPatterns = [
            "login", "signup", "register", "cart", "checkout",
            "download", "install", "pricing", "contact",
            ".zip", ".tar", ".gz", ".exe", ".dmg", ".pkg",
            "mailto:", "tel:", "javascript:", "#"
        ]
        
        for pattern in skipPatterns {
            if path.contains(pattern) || text.contains(pattern) || url.absoluteString.contains(pattern) {
                return false
            }
        }
        
        // Prefer documentation-like links
        let docPatterns = [
            "doc", "guide", "tutorial", "api", "reference",
            "manual", "help", "wiki", "readme", "getting-started",
            "quickstart", "overview", "concepts", "examples"
        ]
        
        for pattern in docPatterns {
            if path.contains(pattern) || text.contains(pattern) {
                return true
            }
        }
        
        // Default to true for internal links, false for external
        return link.linkType == .internal || link.linkType == .subdomain
    }
    
    func stopCrawl() {
        isCrawling = false
        crawlSession = nil
        currentCrawlStatus = "Crawl stopped by user"
    }
    
    func clearCrawlData() {
        discoveredLinks.removeAll()
        crawledPages.removeAll()
        crawlQueue.removeAll()
    }
}

// MARK: - Data Models

struct CrawlSession {
    let rootURL: URL
    let maxDepth: Int
    let maxPagesPerDomain: Int
    let crawlDelay: TimeInterval
    let followExternalLinks: Bool
    let startTime = Date()
}

struct CrawlLink: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let text: String
    let title: String
    let sourceURL: URL
    let depth: Int
    let linkType: LinkType
    
    var displayText: String {
        if !text.isEmpty {
            return text
        } else if !title.isEmpty {
            return title
        } else {
            return url.lastPathComponent
        }
    }
}

struct CrawlTask: Identifiable {
    let id = UUID()
    let url: URL
    let depth: Int
    var status: CrawlTaskStatus = .pending
}

enum LinkType: String, CaseIterable {
    case `internal` = "internal"
    case subdomain = "subdomain"
    case external = "external"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .`internal`:
            return "Internal"
        case .subdomain:
            return "Subdomain"
        case .external:
            return "External"
        case .unknown:
            return "Unknown"
        }
    }
}

enum CrawlTaskStatus {
    case pending
    case processing
    case completed
    case failed(Error)
}

enum CrawlError: LocalizedError {
    case invalidContent
    case crawlLimitExceeded
    case securityViolation
    
    var errorDescription: String? {
        switch self {
        case .invalidContent:
            return "Invalid or empty content"
        case .crawlLimitExceeded:
            return "Crawl limit exceeded"
        case .securityViolation:
            return "Security validation failed"
        }
    }
}
