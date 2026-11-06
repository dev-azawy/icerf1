//
//  TodayView.swift
//  i cerf – App Store style landing tab
//

import SwiftUI
import CoreData
import AltSourceKit
import NimbleViews
import NukeUI

struct TodayView: View {
	@StateObject var viewModel = SourcesViewModel.shared
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .snappy
	) private var _sources: FetchedResults<AltSource>
	
	struct Entry: Identifiable {
		let url: URL?
		let source: ASRepository
		let app: ASRepository.App
		var id: String { app.currentUniqueId }
	}
	
	private var entries: [Entry] {
		var out: [Entry] = []
		for s in _sources {
			guard let repo = viewModel.sources[s] else { continue }
			for a in repo.apps { out.append(Entry(url: s.sourceURL, source: repo, app: a)) }
		}
		return out
	}
	
	private var featured: [Entry] { Array(entries.prefix(6)) }
	
	var body: some View {
		NBNavigationView(.localized("Today")) {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
						.font(.footnote.weight(.semibold))
						.foregroundStyle(.secondary)
						.padding(.horizontal)
					
					if entries.isEmpty {
						Text(.localized("Add a source from the Sources tab to see apps here."))
							.foregroundStyle(.secondary)
							.padding()
					}
					
					ScrollView(.horizontal, showsIndicators: false) {
						LazyHStack(spacing: 16) {
							ForEach(featured) { e in _card(e) }
						}
						.padding(.horizontal)
					}
					
					if !entries.isEmpty {
						Text(.localized("Top Apps"))
							.font(.title2.bold())
							.padding(.horizontal)
						
						LazyVStack(spacing: 12) {
							ForEach(entries) { e in _row(e) }
						}
						.padding(.horizontal)
					}
				}
				.padding(.vertical)
			}
		}
		.task(id: Array(_sources)) { await viewModel.fetchSources(_sources) }
	}
	
	@ViewBuilder
	private func _detail(_ e: Entry) -> some View {
		SourceAppsDetailView(sourceURL: e.url, source: e.source, app: e.app)
	}
	
	@ViewBuilder
	private func _card(_ e: Entry) -> some View {
		NavigationLink {
			_detail(e)
		} label: {
			ZStack(alignment: .bottomLeading) {
				LazyImage(url: e.app.iconURL) { state in
					if let image = state.image {
						image.resizable().scaledToFill().blur(radius: 30).saturation(1.4)
					} else {
						Color.accentColor.opacity(0.4)
					}
				}
				LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
				VStack(alignment: .leading, spacing: 4) {
					Text(e.app.category?.uppercased() ?? "APP")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.white.opacity(0.8))
					Text(e.app.currentName)
						.font(.title.bold())
						.foregroundStyle(.white)
						.lineLimit(2)
					Text(e.app.currentDescription ?? "")
						.font(.footnote)
						.foregroundStyle(.white.opacity(0.85))
						.lineLimit(2)
				}
				.padding(18)
			}
			.frame(width: 310, height: 400)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.2), radius: 10, y: 6)
		}
		.buttonStyle(.plain)
	}
	
	@ViewBuilder
	private func _row(_ e: Entry) -> some View {
		HStack(spacing: 8) {
			NavigationLink {
				_detail(e)
			} label: {
				FRIconCellView(
					title: e.app.currentName,
					subtitle: SourceAppsCellView.appDescription(app: e.app),
					iconUrl: e.app.iconURL
				)
			}
			.buttonStyle(.plain)
			DownloadButtonView(sourceURL: e.url, source: e.source, app: e.app)
		}
	}
}
