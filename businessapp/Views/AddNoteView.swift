import SwiftUI

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notesManager = NotesReminderManager.shared
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: NoteCategory = .general
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Note title (optional)", text: $title)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextEditor(text: $content)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    CategoryButton(category: .general, selected: $selectedCategory)
                                    CategoryButton(category: .businessIdea, selected: $selectedCategory)
                                    CategoryButton(category: .planning, selected: $selectedCategory)
                                    CategoryButton(category: .research, selected: $selectedCategory)
                                    CategoryButton(category: .meetings, selected: $selectedCategory)
                                    CategoryButton(category: .insights, selected: $selectedCategory)
                                }
                            }
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            // Tag input
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Button(action: addTag) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "6366F1"))
                                }
                                .disabled(newTag.isEmpty)
                            }
                            
                            // Tags display
                            if !tags.isEmpty {
                                FlexibleView(
                                    data: tags,
                                    spacing: 8,
                                    alignment: .leading
                                ) { tag in
                                    TagView(tag: tag) {
                                        tags.removeAll { $0 == tag }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func addTag() {
        guard !newTag.isEmpty else { return }
        tags.append(newTag)
        newTag = ""
    }
    
    private func saveNote() {
        notesManager.createNote(
            content: content,
            title: title,
            category: selectedCategory,
            tags: tags
        )
        dismiss()
    }
}

struct CategoryButton: View {
    let category: NoteCategory
    @Binding var selected: NoteCategory
    
    var body: some View {
        Button(action: {
            selected = category
        }) {
            Text(categoryName(category))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selected == category ? .white : .white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected == category ? Color(hex: "6366F1") : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
    
    private func categoryName(_ category: NoteCategory) -> String {
        switch category {
        case .general: return "General"
        case .businessIdea: return "Idea"
        case .planning: return "Planning"
        case .research: return "Research"
        case .meetings: return "Meeting"
        case .insights: return "Insight"
        case .todos: return "To-Do"
        case .inspiration: return "Inspiration"
        }
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 13))
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "6366F1").opacity(0.3))
        .cornerRadius(16)
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            FlexibleContent(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct FlexibleContent<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                    }
                }
            }
        }
    }
    
    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for element in data {
            let elementWidth = element.hashValue % 100 + 80 // Estimate
            
            if remainingWidth - CGFloat(elementWidth) >= 0 {
                rows[currentRow].append(element)
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth
            }
            
            remainingWidth -= CGFloat(elementWidth + Int(spacing))
        }
        
        return rows
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}