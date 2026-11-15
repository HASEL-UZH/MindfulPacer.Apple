import Testing
import Foundation
@testable import iOS

struct MailFallbackTests {
    @Test func mailLinkCarriesRecipientAndEncodedSubject() throws {
        let url = try #require(MailView.mailtoURL(recipient: "support@mindfulpacer.ch", subject: "MindfulPacer - Feedback"))
        #expect(url.absoluteString == "mailto:support@mindfulpacer.ch?subject=MindfulPacer%20-%20Feedback")
    }

    @Test func mailLinkKeepsReservedCharactersInsideSubjectAndBody() throws {
        let url = try #require(MailView.mailtoURL(
            recipient: "support@mindfulpacer.ch",
            subject: "Feedback & ideas = welcome",
            body: "Line 1\nLine 2"
        ))
        #expect(url.scheme == "mailto")
        #expect(!url.absoluteString.contains(" "))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "support@mindfulpacer.ch")
        #expect(components.queryItems == [
            URLQueryItem(name: "subject", value: "Feedback & ideas = welcome"),
            URLQueryItem(name: "body", value: "Line 1\nLine 2")
        ])
    }
}
