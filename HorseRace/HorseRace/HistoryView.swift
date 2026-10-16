//
//  HistoryView.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2026/10/16.
//

import SwiftUI

// 최근 경기 기록 목록 (항목을 누르면 전체 순위를 펼침)
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: RaceRecordStore

    @State private var expandedID: RaceRecord.ID?
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            Color("bgColor")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                if store.records.isEmpty {
                    Spacer()
                    Text("아직 경기 기록이 없어요")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color("subTextColor"))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.records) { record in
                                RecordRow(record: record, isExpanded: expandedID == record.id)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedID = (expandedID == record.id) ? nil : record.id
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .alert("경기 기록을 모두 지울까요?", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                expandedID = nil
                store.removeAll()
            }
            Button("취소", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 20) {
            Text("경기 기록")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(Color("startBtnColor"))

            Text("최근 \(RaceRecordStore.maxCount)경기까지 저장돼요")
                .font(.footnote.bold())
                .foregroundColor(Color("subTextColor"))

            Spacer()

            Button {
                showDeleteAlert = true
            } label: {
                Text("전체 삭제")
                    .font(.subheadline.bold())
                    .foregroundColor(store.records.isEmpty ? Color("subTextColor") : Color("penaltyColor"))
            }
            .disabled(store.records.isEmpty)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(Color("startBtnColor"))
            }
        }
    }
}

private struct RecordRow: View {
    let record: RaceRecord
    let isExpanded: Bool

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(Self.dateFormatter.string(from: record.date))
                    .foregroundColor(Color("subTextColor"))
                Text("\(record.ranking.count)마리")
                    .foregroundColor(Color("subTextColor"))
                Text("🥇 \(record.winnerName)")
                    .foregroundColor(Color("startBtnColor"))
                    .lineLimit(1)

                Spacer()

                if let penalty = record.penalty, let penaltyName = record.penaltyName {
                    Text("벌칙(\(penalty)) → \(penaltyName)")
                        .foregroundColor(Color("penaltyColor"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color("startBtnColor"))
            }
            .font(.subheadline.bold())

            if isExpanded {
                rankingGrid
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        )
        // 빈 공간을 눌러도 펼쳐지도록
        .contentShape(Rectangle())
    }

    private var rankingGrid: some View {
        let preciseIndices = record.preciseIndices
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .leading)],
                         alignment: .leading, spacing: 8) {
            ForEach(record.ranking.indices, id: \.self) { index in
                let entry = record.ranking[index]
                HStack(spacing: 6) {
                    Text("\(index + 1)")
                        .frame(width: 20, alignment: .trailing)
                    Text(entry.name)
                        .lineLimit(1)
                    Text(RaceRanking.formatTime(entry.second, precise: preciseIndices.contains(index)))
                        .foregroundColor(Color("subTextColor"))
                }
                .font(.footnote.bold())
                .foregroundColor(index == record.penaltyRankIndex ? Color("penaltyColor") : Color("startBtnColor"))
            }
        }
    }
}
