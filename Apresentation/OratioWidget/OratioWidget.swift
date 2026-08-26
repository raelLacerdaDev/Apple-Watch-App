//
//  OratioWidget.swift
//  OratioWidget
//
//  Created by Manoel Pedro Prado Sa Teles on 26/08/26.
//

import WidgetKit
import SwiftUI

// Sem dado dinâmico pra mostrar — é só um atalho no mostrador pra abrir o Oratio direto na
// tela de início de sessão (ReadyView), via deep link "oratio://start" (ver RouteView.onOpenURL).
// Uma única entrada estática, nunca recarrega.
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [SimpleEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct OratioWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "mic.fill")
                    .font(.title3)
            }

        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.body)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Oratio")
                        .font(.headline)
                    Text("Iniciar apresentação")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

        case .accessoryInline:
            Label("Oratio", systemImage: "mic.fill")

        case .accessoryCorner:
            Image(systemName: "mic.fill")
                .widgetLabel("Oratio")

        default:
            Image(systemName: "mic.fill")
        }
    }
}

struct OratioWidget: Widget {
    let kind: String = "OratioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OratioWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "oratio://start"))
        }
        .configurationDisplayName("Oratio")
        .description("Inicie sua apresentação direto do mostrador.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

#Preview(as: .accessoryCircular) {
    OratioWidget()
} timeline: {
    SimpleEntry(date: .now)
}

#Preview(as: .accessoryRectangular) {
    OratioWidget()
} timeline: {
    SimpleEntry(date: .now)
}
