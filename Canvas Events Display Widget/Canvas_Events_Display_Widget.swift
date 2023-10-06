//
//  Canvas_Events_Display_Widget.swift
//  Canvas Events Display Widget
//
//  Created by Zackery He on 10/3/23.
//

import WidgetKit
import SwiftUI
import Foundation

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), list: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), list: [])
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let dateFormatter = ISO8601DateFormatter()
        //from UTC to PST time
        let todaysDate = Calendar.current.date(byAdding: .hour, value: -7, to: Date())!
//        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: todaysDate)!
        let startDate = todaysDate
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

            print(courses)
            var allAssignmentsData: [Assignment] = []
            var currentCourse = 0
            
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
//
                        for assignmentItem in assignments {
                            allAssignmentsData.append(Assignment(id: assignmentItem.assignment.id, due_at: assignmentItem.assignment.due_at, name: assignmentItem.assignment.name))
                        }
                        
                        print("got data")
                        currentCourse += 1
                        print(currentCourse)
                    
                        if (currentCourse == courses.count) {
                            print("submitted timeline")
                            
                            print(allAssignmentsData)
                            allAssignmentsData.sort { $0.due_at < $1.due_at }
                            let entry = SimpleEntry(date: Date(), list: Array(allAssignmentsData.prefix(7)))
                            let timeline = Timeline(entries: [entry], policy: .after(.now.advanced(by: 60*15)))
                            completion(timeline)
                        }
                        
                       
                    } catch {
                        print("assignments--error")
                    }
                }
                task.resume()
            }
        }
        task.resume()

    }
}


struct SimpleEntry: TimelineEntry {
    let date: Date
    let list: [Assignment]
}


struct Canvas_Events_Display_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text("Today").padding(.top).foregroundColor(.red).bold().font(.system(size: 11))
            Divider().frame(height: 0.5).background(Color.gray.opacity(0.2))
            
            ForEach(0..<entry.list.count) { i in
                let assignment = entry.list[i]
                let yesterdayIndex = i - 1 >= 0 ? i - 1 : i
                let yesterday = getWeekday(from: "\(entry.list[yesterdayIndex].due_at)") ?? "invalid date"
                let todayDay = getWeekday(from: "\(assignment.due_at)") ?? "invalid date"

                let date = formatDateString(from: "\(assignment.due_at)") ?? "invalid date"
            
                if yesterday != todayDay {
                    Text(todayDay).foregroundColor(.gray).bold().font(.system(size: 11))
                }

            
                
                Group {
                    HStack {
                        Divider().padding(7).frame(width: 3).overlay(.pink).cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
                        Text("\(assignment.name)").bold().font(.system(size: 11)).padding().foregroundColor(.purple)

                        Spacer()
                        Text(date).padding().font(.system(size: 10)).foregroundColor(.purple)
                    }
                }.padding(.bottom, 4)
                    .frame(height: 25)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
            }
            Spacer()
        }
        .containerBackground(for: .widget) {
            Color(red: 0.157, green: 0.157, blue: 0.157)
        }

    }
    
    func getWeekday(from dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let weekdayName = calendar.weekdaySymbols[weekday - 1]
            return weekdayName
        } else {
            return nil
        }
    }
    
    func formatDateString(from dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        }
        return nil
    }
}

struct Canvas_Events_Display_Widget: Widget {
    let kind: String = "Canvas_Events_Display_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Canvas_Events_Display_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("my widget")
        .description("my desc")
    }
}

struct Courses: Decodable {
    var name: String
    var id: Int
}

struct Assignments: Decodable {
    var assignment: Assignment
}

struct Assignment: Decodable, Identifiable {
    var id: Int
    var due_at: String
    var name: String
}
