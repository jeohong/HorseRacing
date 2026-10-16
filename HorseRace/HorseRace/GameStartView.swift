//
//  GameStartView.swift
//  HorseRace
//
//  Created by Hong jeongmin on 2022/08/23.
//

import SwiftUI

struct GameStartView: View {
    @ObservedObject var game: GameState
    
    @State private var showCreditView = false
    @State private var isStarting = false
    @FocusState private var focusedHorse: Int?
    
    var body: some View {
        ZStack {
            Image("startBgImg")
                .resizable()
                .ignoresSafeArea()
                .frame(width: UIScreen.current.bounds.width, height: UIScreen.current.bounds.height + 20)
                .scaledToFill().clipped()
            
            VStack {
                HStack {
                    Button {
                        showCreditView = true
                    } label: {
                        Image("InformationMark")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .fullScreenCover(isPresented: $showCreditView) {
                        CreditView()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button {
                        if game.decreaseHorseCount() {
                            SoundSetting.shared.play(.change)
                        } else {
                            SoundSetting.shared.play(.negative)
                        }
                    } label: {
                        Circle()
                            .foregroundColor(Color("startBtnColor"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "minus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.top, 25)
                    
                    Text("\(game.horseCount)")
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundColor(Color("startBtnColor"))
                        .padding([.leading, .trailing], 10)
                        .padding(.top, 25)
                    
                    Button {
                        if game.increaseHorseCount() {
                            SoundSetting.shared.play(.change)
                        } else {
                            SoundSetting.shared.play(.negative)
                        }
                    } label: {
                        Circle()
                            .foregroundColor(Color("startBtnColor"))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.top, 25)
                }
                .padding()
                
                Text("말의 이름을 터치하여 말의 이름을 변경할 수 있습니다!")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color("startBtnColor"))
                
                Spacer()
                
                HStack(spacing: 0) {
                    ForEach(1...game.horseCount, id:\.self) { num in
                        VStack {
                            Image("horse\(num)").resizable()
                                .frame(maxHeight: 200, alignment: .center)
                                .scaledToFit()
                            
                            TextField("", text: $game.horseNames[num - 1])
                                .focused($focusedHorse, equals: num)
                                .placeholder(when: game.horseNames[num - 1].isEmpty && focusedHorse != num) {
                                    Text("\(num)번마")
                                        .foregroundColor(.white)
                                }
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                
                Text("자신의 말을 기억해 주세요!")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color("startBtnColor"))
                
                Button {
                    SoundSetting.shared.play(.startButton)
                    isStarting = true
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 92, height: 37, alignment: .center)
                        .foregroundColor(Color("startBtnColor"))
                        .overlay(
                            Text("시작하기")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .heavy))
                        )
                        .padding()
                }
                // 연타로 경주가 여러 번 시작되지 않도록
                .disabled(isStarting)
            }
        }
        // 버튼 효과음 후 0.5초 뒤 시작, 화면이 사라지면 자동으로 취소됨
        .task(id: isStarting) {
            guard isStarting else { return }
            guard (try? await Task.sleep(seconds: 0.5)) != nil else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                game.startRace()
            }
        }
        .onTapGesture {
            self.endTextEditing()
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}
