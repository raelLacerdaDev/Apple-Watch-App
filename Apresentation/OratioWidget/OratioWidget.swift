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
        // .widgetAccentable() marca o que deve pegar a cor de destaque do mostrador nos modos
        // "tintado"/"acentuado" (a maioria dos mostradores não deixa a gente escolher cor livre —
        // isso é o que faz o ícone acompanhar o tema de cada mostrador em vez de ficar cinza fixo).
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 22, weight: .semibold))
                    .widgetAccentable()
            }

        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 20, weight: .semibold))
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text("Oratio")
                        .font(.headline)
                    Text("Toque para começar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

        case .accessoryInline:
            Label("Nova apresentação", systemImage: "waveform.and.mic")

        case .accessoryCorner:
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 18, weight: .semibold))
                .widgetAccentable()
                .widgetLabel("Oratio")

        default:
            Image(systemName: "waveform.and.mic")
        }
    }
}

struct OratioWidget: Widget {
    let kind: String = "OratioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            OratioWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "oratio://start"))
                // Obrigatório em dispositivo real (diferente do simulador) — sem isso o watchOS
                // mostra "Please adopt containerBackground API" no lugar do conteúdo. Transparente
                // porque as famílias accessory (mostrador) já recebem o fundo certo do sistema.
                .containerBackground(for: .widget) { Color.clear }
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
