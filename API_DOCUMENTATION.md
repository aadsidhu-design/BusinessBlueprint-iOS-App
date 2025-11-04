# Business Blueprint - API Documentation

## Google AI Studio Integration

### GoogleAIService Overview
Handles all AI-powered features including business idea generation and AI suggestions.

### API Endpoints

#### 1. Generate Business Ideas
```swift
GoogleAIService.shared.generateBusinessIdeas(
    skills: ["Programming", "Design"],
    personality: ["Creative", "Analytical"],
    interests: ["Technology", "Business"]
) { result in
    switch result {
    case .success(let ideas):
        // Handle ideas array
    case .failure(let error):
        // Handle error
    }
}
```

**Request:**
- Base URL: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`
- Method: POST
- Headers: `Content-Type: application/json`
- Query: `?key=YOUR_API_KEY`

**Response:**
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Generated business ideas..."
          }
        ]
      }
    }
  ]
}
```

#### 2. Get AI Suggestions
```swift
GoogleAIService.shared.getAISuggestions(
    businessIdea: ideaObject
) { result in
    switch result {
    case .success(let suggestions):
        // Handle suggestions
    case .failure(let error):
        // Handle error
    }
}
```

**Parameters:**
- `businessIdea`: BusinessIdea object with all details
- Returns: Actionable next steps and recommendations

**Response:**
```
Practical advice and next steps for implementation
including:
- Market validation steps
- Initial setup requirements
- Resource recommendations
- Timeline estimates
```

## Firebase Integration

### Authentication Service

#### Sign Up
```swift
FirebaseService.shared.signUpUser(
    email: "user@example.com",
    password: "securePassword"
) { result in
    // Handle result
}
```

#### Sign In
```swift
FirebaseService.shared.signInUser(
    email: "user@example.com",
    password: "securePassword"
) { result in
    // Handle result
}
```

#### Sign Out
```swift
FirebaseService.shared.signOutUser { result in
    // Handle result
}
```

### Firestore Database Operations

#### Save Business Idea
```swift
FirebaseService.shared.saveBusinessIdea(idea) { result in
    // Handle result
}
```

**Firestore Path:** `/businessIdeas/{userId}/{ideaId}`

**Data Structure:**
```json
{
  "title": "String",
  "description": "String",
  "category": "String",
  "difficulty": "String",
  "estimated_revenue": "String",
  "time_to_launch": "String",
  "required_skills": ["String"],
  "startup_cost": "String",
  "profit_margin": "String",
  "market_demand": "String",
  "competition": "String",
  "created_at": "Timestamp",
  "user_id": "String",
  "personalized_notes": "String",
  "saved": "Boolean",
  "progress": "Number"
}
```

#### Fetch Business Ideas
```swift
FirebaseService.shared.fetchBusinessIdeas(userId: userId) { result in
    switch result {
    case .success(let ideas):
        // Handle ideas array
    case .failure(let error):
        // Handle error
    }
}
```

#### Save Daily Goal
```swift
FirebaseService.shared.saveDailyGoal(goal) { result in
    // Handle result
}
```

**Firestore Path:** `/goals/{userId}/{goalId}`

**Data Structure:**
```json
{
  "title": "String",
  "description": "String",
  "business_idea_id": "String",
  "due_date": "Timestamp",
  "completed": "Boolean",
  "priority": "String",
  "created_at": "Timestamp",
  "user_id": "String"
}
```

#### Fetch Daily Goals
```swift
FirebaseService.shared.fetchDailyGoals(userId: userId) { result in
    // Handle result
}
```

#### Save Milestone
```swift
FirebaseService.shared.saveMilestone(milestone) { result in
    // Handle result
}
```

**Firestore Path:** `/milestones/{businessIdeaId}/{milestoneId}`

**Data Structure:**
```json
{
  "title": "String",
  "description": "String",
  "business_idea_id": "String",
  "due_date": "Timestamp",
  "completed": "Boolean",
  "order": "Number",
  "created_at": "Timestamp",
  "user_id": "String"
}
```

#### Fetch Milestones
```swift
FirebaseService.shared.fetchMilestones(
    businessIdeaId: ideaId
) { result in
    // Handle result
}
```

#### Save User Profile
```swift
FirebaseService.shared.saveUserProfile(profile) { result in
    // Handle result
}
```

**Firestore Path:** `/users/{userId}/profile`

**Data Structure:**
```json
{
  "email": "String",
  "first_name": "String",
  "last_name": "String",
  "skills": ["String"],
  "personality": ["String"],
  "interests": ["String"],
  "created_at": "Timestamp",
  "subscription_tier": "String"
}
```

#### Fetch User Profile
```swift
FirebaseService.shared.fetchUserProfile(userId: userId) { result in
    switch result {
    case .success(let profile):
        // Handle profile
    case .failure(let error):
        // Handle error
    }
}
```

#### Update Business Idea Progress
```swift
FirebaseService.shared.updateBusinessIdeaProgress(
    ideaId: ideaId,
    progress: 50
) { result in
    // Handle result
}
```

## Firebase Security Rules

### Recommended Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User-specific rules
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Business Ideas - User can read/write own ideas
    match /businessIdeas/{userId}/{ideaId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Goals - User can read/write own goals
    match /goals/{userId}/{goalId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Milestones - User can read/write milestones for their ideas
    match /milestones/{ideaId}/{milestoneId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Invalid API Key | Expired or wrong key | Update API key in FirebaseConfig |
| Network Error | No internet connection | Implement offline mode |
| Authentication Failed | Invalid credentials | Validate email/password |
| Firebase Not Initialized | Missing GoogleService-Info.plist | Add plist to Xcode project |
| Rate Limited | Too many API requests | Implement request throttling |

### Error Response Format
```swift
struct APIError: Error {
    let code: String
    let message: String
    let details: [String: Any]?
}
```

## Rate Limiting

### Google AI Studio
- **Requests per minute:** Varies by tier
- **Daily quotas:** Subject to plan

### Firebase
- **Realtime Database:** 25 connections per user
- **Firestore:** 50,000 reads/day free tier

## Authentication Headers

```swift
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
User-Agent: BusinessBlueprint/1.0
```

## Response Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 429 | Rate Limited |
| 500 | Server Error |

## Pagination

### Firestore Queries
```swift
let query = db.collection("businessIdeas")
    .document(userId)
    .collection("ideas")
    .limit(to: 10)
    .start(afterDocument: lastDocument)
```

## Caching Strategy

```swift
// Implement offline-first caching
// Use UserDefaults for temporary storage
// Cache AI responses for 24 hours
// Implement cache invalidation
```

## Best Practices

1. **Always validate user input** before API calls
2. **Implement retry logic** for failed requests
3. **Use Codable** for JSON serialization
4. **Cache responses** appropriately
5. **Handle errors gracefully** with user feedback
6. **Monitor API usage** through dashboard
7. **Rotate API keys** regularly
8. **Use HTTPS** for all connections
9. **Implement request throttling**
10. **Test with mock data** first

## Testing API Integration

```swift
// Unit test example
func testGenerateBusinessIdeas() {
    let mockSkills = ["Programming", "Design"]
    let expectation = XCTestExpectation(description: "Ideas generated")
    
    GoogleAIService.shared.generateBusinessIdeas(
        skills: mockSkills,
        personality: [],
        interests: []
    ) { result in
        switch result {
        case .success(let ideas):
            XCTAssertGreaterThan(ideas.count, 0)
            expectation.fulfill()
        case .failure:
            XCTFail("Should not fail")
        }
    }
    
    wait(for: [expectation], timeout: 10.0)
}
```

## Rate Limit Headers

Look for these headers in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1234567890
```

## Webhook Support (Future)

```javascript
// Example webhook for subscription changes
POST /webhooks/subscription
{
  "event": "subscription.upgraded",
  "userId": "user123",
  "newTier": "premium",
  "timestamp": "2024-11-04T10:00:00Z"
}
```

---

**API documentation complete. Ready for integration!**
