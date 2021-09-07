/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

enum FileError: Error {
    case loadFailure
    case saveFailure
    case urlFailure
}


struct ExerciseDay: Identifiable {
    let id = UUID()
    let date: Date
    var exercises: [String] = []
}

class HistoryStore: ObservableObject {
    @Published var exerciseDays: [ExerciseDay] = []
    
    init() {}
    
    init(withChecking: Bool) throws {
        #if DEBUG
        //    createDevData()
        #endif
        
        do {
            try load()
        } catch {
            throw error
        }
    }
    
    func getURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask).first else {
            // 1 leave method if condition test fails
            return nil
        }
        // 2 Add file name of document path
        return
            documentsURL.appendingPathComponent("history.plist")
    }
    
    func load() throws {
        // 1 Set up URL like we do with save
        guard let dataURL = getURL() else {
            throw FileError.urlFailure
        }
        
        
        // 2 read data file into a byte buffer
        guard let data = try? Data(contentsOf: dataURL) else { return }
        // 3 Convert property list into format that app can read
        let plistData = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        // 4 Type cast t make sure type still Any
        let convertedPlistData = plistData as? [[Any]] ?? []
        // 5  use map to each element to type Any
        exerciseDays = convertedPlistData.map {
            ExerciseDay(date: $0[1] as? Date ?? Date(), exercises: $0[2] as? [String] ?? [])
        }
    }
    
    func save() throws {
        guard let dataURL = getURL()
        else {
            throw FileError.urlFailure
        }
        
        let plistData = exerciseDays.map {
            [ $0.id.uuidString,
              $0.date,
              $0.exercises
            ]
        }
        
        do {
            // 1 Convert historyData in property list format
            let data = try PropertyListSerialization.data(
                fromPropertyList: plistData,
                format: .binary,
                options: .zero)
            
            // 2 write to disk using URL
            try data.write(to: dataURL, options: .atomic)
        } catch {
            // 3 writing and conversion may throw an error
            throw FileError.saveFailure
        }
    }
    
    func addDoneExercise(_ exerciseName: String) {
        let today = Date()
        if let firstDate = exerciseDays.first?.date, today.isSameDay(as: firstDate) {
            print("Adding \(exerciseName)")
            exerciseDays[0].exercises.append(exerciseName)
        } else {
            exerciseDays.insert(
                ExerciseDay(date: today, exercises: [exerciseName]),
                at: 0)
        }
        do {
            try save()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
