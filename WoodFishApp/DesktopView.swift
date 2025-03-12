import SwiftUI

struct DesktopView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                        Text("返回")
                            .font(.custom("SourceHanSerifCN-Heavy", size: 18))
                    }
                    .foregroundColor(Color(hex: "592424"))
                }
                .padding()
                
                Spacer()
            }
            
            // 标题
            Text("如何添加桌面小组件?")
                .font(.custom("SourceHanSerifCN-Heavy", size: 28))
                .foregroundColor(Color(hex: "592424"))
                .padding(.top, 30)
            
            // 步骤说明
            VStack(alignment: .leading, spacing: 40) {
                // 第一步
                VStack(alignment: .leading, spacing: 16) {
                    Text("1. 长按随身拜图标，进入编辑模式。")
                        .font(.custom("SourceHanSerifCN-Heavy", size: 20))
                        .foregroundColor(Color(hex: "592424"))
                    
                    Image("step1_image") // 添加第一步的示意图
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                }
                
                // 第二步
                VStack(alignment: .leading, spacing: 16) {
                    Text("2. 点击小组件，选择不同的样式。")
                        .font(.custom("SourceHanSerifCN-Heavy", size: 20))
                        .foregroundColor(Color(hex: "592424"))
                    
                    Image("step2_image") // 添加第二步的示意图
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F8F5E4"))
    }
}

// 预览
struct DesktopView_Previews: PreviewProvider {
    static var previews: some View {
        DesktopView()
    }
} //
//  DesktopView.swift
//  WoodFishApp
//
//  Created by 张栩萌 on 2025/3/10.
//

