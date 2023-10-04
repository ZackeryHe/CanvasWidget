//
//  Canvas_Events_Display_Widget.swift
//  Canvas Events Display Widget
//
//  Created by Zackery He on 10/3/23.
//

import WidgetKit
import SwiftUI
import Foundation

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        let dateFormatter = ISO8601DateFormatter()
        //from UTC to PST time
        let todaysDate = Calendar.current.date(byAdding: .hour, value: -7, to: Date())!
        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: todaysDate)!
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: todaysDate)!
//        let dateString = dateFormatter.string(from: endDate)
        
        let url = URL(string: "https://canvas.instructure.com/api/v1/courses?access_token=4407~raaHhBFkfUO3st3C42lHjv0TtMuCCR3rvXkXlR1x7e2ktJw1QiVAE8VNhteDdRoj")!
       
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            var courses: [String] = []
            guard let data = data else {return}
            
            do {
                let courseIds = try JSONDecoder().decode([Courses].self, from: data)
                for id in courseIds {
                    courses.append("\(id.id)")
                }
            } catch {
                print("err")
            }
            //.suffix(6)
            print(courses)
            for courseId in courses {
                let temp1 = "https://canvas.eee.uci.edu/api/v1/calendar_events?access_token=4407~raaHhBFkfUO3st3C42lHjv0TtMuCCR3rvXkXlR1x7e2ktJw1QiVAE8VNhteDdRoj"
                    + "&type=assignment"
                let temp2 = "&context_codes%5B%5D=course_" + courseId.suffix(5)
                let temp3 = "&start_date=" + dateFormatter.string(from: startDate)
                let temp4 = "&end_date=" + dateFormatter.string(from: endDate)
                let temp5 = temp3 + temp4
                let wholeString = temp1 + temp2 + temp5
                print(wholeString)
                let url = URL(string: wholeString)!
                
                let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                    guard let data = data else {return}
    
                    do {
                        let assignments = try JSONDecoder().decode([Assignments].self, from: data)
                        
                        for assignmentItem in assignments {
                            print("\(assignmentItem.title)")
                        }
                    } catch {
                        print("assignments error")
                    }
                }
                task.resume()
            }
        }
        task.resume()
        
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let entry = SimpleEntry(date: entryDate, configuration: configuration)
        entries.append(entry)

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct Canvas_Events_Display_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

        }
    }
}

struct Canvas_Events_Display_Widget: Widget {
    let kind: String = "Canvas_Events_Display_Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            Canvas_Events_Display_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct Courses: Decodable {
    var name: String
    var id: Int
}

struct Assignments: Decodable {
    var title: String
}
