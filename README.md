# Project Tokei
トケイプロジェクトは、24時間のアナログ時計UIを通じて、ユーザーが一目でその日のスケジュールを把握できるよう、直感的な視覚化を提供することを目標に制作されました。
また、AI分析機能を活用して効率的な時間管理と最適なスケジュール提案を提供することで、
ユーザーに有益なスケジュール管理体験を実現することを目指しております。

<div style="display: flex; flex-wrap: wrap;">
  <img src="https://github.com/user-attachments/assets/b99829a1-6f10-4ecc-90bb-c81a6dc37939" width="200" style="margin-right: 10px; margin-bottom: 10px;" />
  <img src="https://github.com/user-attachments/assets/1efa9ef8-2298-498e-b443-d46d3939ae8c" width="200" style="margin-right: 10px; margin-bottom: 10px;" />
  <img src="https://github.com/user-attachments/assets/c1a84037-9fe2-4422-961c-30af7a18414e" width="200" style="margin-right: 10px; margin-bottom: 10px;" />
  <img src="https://github.com/user-attachments/assets/5b43127d-aa43-4f5d-8891-9e8e791749e8" width="200" style="margin-right: 10px; margin-bottom: 10px;" />
</div>

## :warning: 주의!
>
> ```plaintext
> セキュリティ上の理由により、OpenAI APIキーをコードから削除しました。
> すべての機能をご利用になりたい場合は、`zenga85@naver.com`までご連絡ください。
> ```
>
> ```plaintext
> For security reasons, the OpenAI API Key has been removed from the code.
> If you wish to use all functionalities, please contact `zenga85@naver.com`.
> ```

## :hammer_and_wrench: プロジェクト トケイ 技術スタック

### iOS (Swift)
- **SwiftUI**  
  - 宣言型UIを用いた開発  
  - Path/Shapeを活用したカスタムアナログ時計の実装
- **MVVMアーキテクチャ**  
  - ObservableObjectと@PublishedでデータとUIの状態を分離
- **UIKitとの統合**  
  - UIDevice、UITraitCollectionなどのUIKit機能をSwiftUIと組み合わせて使用
- **UserDefaults (JSON直列化)**  
  - スケジュールデータや色情報をJSONでエンコード/デコードして保存
- **Timer.publish**  
  - 時計の針の動きなど、リアルタイムUI更新のためにタイマーイベントを利用
- **ダークモード対応**  
  - システムモード連動および手動ダークモード切替に対応

### AI連携
- **OpenAI API**  
  - スケジュール分析および時間管理アドバイス機能を実装（ScheduleAnalyzerクラスで管理）

### ビルド/デプロイ環境
- **Xcode**  
  - iOSアプリの開発およびシミュレーション
