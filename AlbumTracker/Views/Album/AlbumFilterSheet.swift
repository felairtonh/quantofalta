import SwiftUI

struct AlbumFilterSheet: View {
    @Bindable var viewModel: AlbumViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Show", selection: $viewModel.statusFilter) {
                        ForEach(AlbumViewModel.StatusFilter.allCases, id: \.self) {
                            Text(LocalizedStringKey($0.rawValue)).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Type") {
                    Picker("Type", selection: $viewModel.typeFilter) {
                        ForEach(AlbumViewModel.TypeFilter.allCases, id: \.self) {
                            Text(LocalizedStringKey($0.rawValue)).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Team", selection: $viewModel.teamFilter) {
                        Text("All Teams").tag(String?.none)
                        ForEach(viewModel.teams, id: \.code) { team in
                            Text("\(team.flag ?? "")  \(team.name.localizedName)").tag(String?.some(team.code))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Sort") {
                    Picker("Order", selection: $viewModel.sortMode) {
                        ForEach(AlbumViewModel.SortMode.allCases, id: \.self) {
                            Text(LocalizedStringKey($0.rawValue)).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    Picker("Direction", selection: $viewModel.sortAscending) {
                        Text("Ascending").tag(true)
                        Text("Descending").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Reset Filters", role: .destructive) {
                        withAnimation {
                            viewModel.statusFilter = .all
                            viewModel.typeFilter = .all
                            viewModel.teamFilter = nil
                        }
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }
            }
            .navigationTitle("Sort & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
