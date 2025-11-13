import SwiftUI

struct BusinessPlanWizard: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var businessPlan = BusinessPlanData()
    
    private let steps = [
        "Basic Info",
        "Market Analysis", 
        "Financial Planning",
        "Goals & Timeline"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader
                    
                    // Content
                    TabView(selection: $currentStep) {
                        BasicInfoStep(businessPlan: $businessPlan)
                            .tag(0)
                        
                        MarketAnalysisStep(businessPlan: $businessPlan)
                            .tag(1)
                        
                        FinancialPlanningStep(businessPlan: $businessPlan)
                            .tag(2)
                        
                        GoalsTimelineStep(businessPlan: $businessPlan)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color(red: 0.0, green: 0.8, blue: 0.6))
                        .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(steps.count), height: 4)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            
            Text(steps[currentStep])
                .font(.title2.bold())
                .foregroundColor(.black)
                .padding(.bottom, 10)
        }
        .padding(.top, 10)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Previous") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(currentStep == steps.count - 1 ? "Create Plan" : "Next") {
                if currentStep == steps.count - 1 {
                    createBusinessPlan()
                } else {
                    withAnimation {
                        currentStep += 1
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 0.0, green: 0.8, blue: 0.6))
            .cornerRadius(12)
            .disabled(!canProceed)
            .opacity(canProceed ? 1.0 : 0.6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !businessPlan.name.isEmpty && !businessPlan.description.isEmpty
        case 1: return !businessPlan.targetMarket.isEmpty
        case 2: return businessPlan.startupCost > 0
        case 3: return !businessPlan.goals.isEmpty
        default: return true
        }
    }
    
    private func createBusinessPlan() {
        let businessIdea = BusinessIdea(
            id: UUID().uuidString,
            title: businessPlan.name,
            description: businessPlan.description,
            category: businessPlan.industry,
            difficulty: businessPlan.difficulty,
            estimatedRevenue: "$\(Int(businessPlan.projectedRevenue))K",
            timeToLaunch: businessPlan.timeToLaunch,
            requiredSkills: businessPlan.requiredSkills,
            startupCost: "$\(Int(businessPlan.startupCost))K",
            profitMargin: "\(Int(businessPlan.profitMargin))%",
            marketDemand: businessPlan.marketDemand,
            competition: businessPlan.competition,
            createdAt: Date(),
            userId: "",
            personalizedNotes: businessPlan.notes,
            saved: true,
            progress: 0
        )
        
        // Add to business plan store
        businessPlanStore.updateIdea(businessIdea)
        businessPlanStore.selectIdea(businessIdea)
        
        isPresented = false
    }
}

struct BusinessPlanData {
    var name = ""
    var description = ""
    var industry = "Technology"
    var targetMarket = ""
    var startupCost: Double = 0
    var projectedRevenue: Double = 0
    var profitMargin: Double = 0
    var timeToLaunch = "6-12 months"
    var difficulty = "Medium"
    var marketDemand = "Medium"
    var competition = "Medium"
    var requiredSkills: [String] = []
    var goals: [String] = []
    var notes = ""
}

struct BasicInfoStep: View {
    @Binding var businessPlan: BusinessPlanData
    
    private let industries = ["Technology", "Healthcare", "Finance", "Education", "Retail", "Food & Beverage", "Real Estate", "Manufacturing", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Business Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    TextField("Enter your business name", text: $businessPlan.name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    TextField("Describe your business idea", text: $businessPlan.description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Industry")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    Picker("Industry", selection: $businessPlan.industry) {
                        ForEach(industries, id: \.self) { industry in
                            Text(industry).tag(industry)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
    }
}

struct MarketAnalysisStep: View {
    @Binding var businessPlan: BusinessPlanData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Market")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    TextField("Who are your customers?", text: $businessPlan.targetMarket, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Market Demand")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    Picker("Market Demand", selection: $businessPlan.marketDemand) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Competition Level")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    Picker("Competition", selection: $businessPlan.competition) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(20)
        }
    }
}

struct FinancialPlanningStep: View {
    @Binding var businessPlan: BusinessPlanData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Startup Cost (in thousands)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("$")
                        TextField("0", value: $businessPlan.startupCost, format: .number)
                            .textFieldStyle(.roundedBorder)
                        Text("K")
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Projected Annual Revenue (in thousands)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("$")
                        TextField("0", value: $businessPlan.projectedRevenue, format: .number)
                            .textFieldStyle(.roundedBorder)
                        Text("K")
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expected Profit Margin (%)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    HStack {
                        TextField("0", value: $businessPlan.profitMargin, format: .number)
                            .textFieldStyle(.roundedBorder)
                        Text("%")
                    }
                }
            }
            .padding(20)
        }
    }
}

struct GoalsTimelineStep: View {
    @Binding var businessPlan: BusinessPlanData
    @State private var newGoal = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time to Launch")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    Picker("Time to Launch", selection: $businessPlan.timeToLaunch) {
                        Text("1-3 months").tag("1-3 months")
                        Text("3-6 months").tag("3-6 months")
                        Text("6-12 months").tag("6-12 months")
                        Text("1+ years").tag("1+ years")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Goals")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    HStack {
                        TextField("Add a goal", text: $newGoal)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Add") {
                            if !newGoal.isEmpty {
                                businessPlan.goals.append(newGoal)
                                newGoal = ""
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.0, green: 0.8, blue: 0.6))
                        .cornerRadius(8)
                    }
                    
                    ForEach(Array(businessPlan.goals.enumerated()), id: \.offset) { index, goal in
                        HStack {
                            Text(goal)
                                .foregroundColor(.black)
                            Spacer()
                            Button {
                                businessPlan.goals.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Notes")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.black)
                    
                    TextField("Any additional thoughts or ideas", text: $businessPlan.notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    BusinessPlanWizard(isPresented: .constant(true))
        .environmentObject(BusinessPlanStore())
}