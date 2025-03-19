import Foundation

class ScheduleAnalyzer {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func analyzeSchedule(schedules: [Schedule], completion: @escaping (String?) -> Void) {
        // 일정이 없는 경우 바로 메시지 반환
        if schedules.isEmpty {
            completion("오늘은 등록된 일정이 없습니다.\n\n새로운 일정을 추가하여 하루를 계획해보세요.")
            return
        }
        
        var scheduleDescriptions = ""
        
        // 일정들을 시간순으로 정렬
        let sortedSchedules = schedules.sorted { s1, s2 in
            let time1 = s1.hour * 60 + s1.minutes
            let time2 = s2.hour * 60 + s2.minutes
            return time1 < time2
        }
        
        // 일정 설명 생성
        for schedule in sortedSchedules {
            let startTime = String(format: "%02d:%02d", schedule.hour, schedule.minutes)
            let endTime = String(format: "%02d:%02d", schedule.endHour, schedule.endMinutes)
            scheduleDescriptions += "\(startTime)-\(endTime): \(schedule.title)\n"
        }
        
        // API 요청 생성
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "당신은 일정을 분석하고 조언해주는 전문가입니다. 분석은 한국어로 해주세요. 주어진 일정만 분석하고 없는 일정을 만들어내지 마세요."],
                ["role": "user", "content": """
                다음은 오늘의 일정입니다. 이 일정들을 분석하고, 시간 관리나 일정 배치에 대한 조언을 해주세요:
                \(scheduleDescriptions)
                """]
            ],
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error creating request body: \(error)")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error with API request: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from API")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    print("Could not extract message from response")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(dataString)")
                    }
                    completion(nil)
                }
            } catch {
                print("Error parsing response: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
