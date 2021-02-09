//
//  ViewController.swift
//  Copresent
//
//  Created by Jon Reiling on 1/12/21.
//

import Cocoa
import Alamofire
import SocketIO

struct Meeting:Decodable  {
    let id: String
    let entrycode: String
    let participants: Array<String>
}

class ViewController: NSViewController {

    var baseUrl:String = "http://localhost:3000"
    @IBOutlet var urlField:NSTextField!
    @IBOutlet var entryCodeField:NSTextField!
    @IBOutlet var startButton:NSButton!
    @IBOutlet var statusImage:NSImageView!
    @IBOutlet var roomNameField:NSTextField!
    @IBOutlet var participantHeader:NSTextField!
    @IBOutlet var participantField:NSTextField!
    var currentMeeting:Meeting?
    var socketManager:SocketManager?
    var socket:SocketIOClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url:String = Bundle.main.object(forInfoDictionaryKey: "Remote_Server_Address") as? String {
            baseUrl = url.replacingOccurrences(of: "\\", with: "")
        }
        
        print("Base url",baseUrl)
        socketManager = SocketManager(socketURL: URL(string: baseUrl)!, config: [.log(true), .compress])
  //      baseURL = Bundle.main.object(forInfoDictionaryKey: "Remote_Server_Address")
//        print("REMOTE_SERVER_ADDRESS",Bundle.main.object(forInfoDictionaryKey: "Remote_Server_Address"))
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func toggleStartStop(sender:Any) {

        if ( currentMeeting == nil ) {
            createMeeting()
        } else {
            destroyMeeting()
        }
        
    }
    
    @IBAction func copyMeetingToClipboard(sender:Any) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(urlField.stringValue, forType: .string)
    }
    
    private func createMeeting() {
        print("make request")

        if ( roomNameField.stringValue.isEmpty ) {
            return
        }
        
        let parameters: [String: String] = [
            "name": roomNameField.stringValue
        ]
        
        AF.request(baseUrl + "/m/create",
                   method: .post,
                   parameters: parameters).responseJSON { response in
            print("recieved")

            let decoder = JSONDecoder()
            let meeting = try! decoder.decode(Meeting.self, from: response.data!)
            self.setCurrentMeeting(meeting:meeting)
        }

        startButton.title = "Stop"
    }
    
    private func destroyMeeting() {
        
        socket?.disconnect()
        socket = nil
        
        let parameters: [String: String] = [
            "id": currentMeeting!.id,
            "entrycode": currentMeeting!.entrycode
        ]

        AF.request(baseUrl + "/m/destroy",
                   method: .post,
                   parameters: parameters,
                   headers: nil).responseJSON { response in
            
                    self.currentMeeting = nil
                    self.urlField.stringValue = ""
                    self.entryCodeField.stringValue = ""

                   
        }
        
        startButton.title = "Start"
    }

    private func setCurrentMeeting(meeting:Meeting) {

        urlField.stringValue = baseUrl + "/m/" + meeting.id + "/?entrycode=" + meeting.entrycode
        entryCodeField.stringValue = meeting.entrycode
        currentMeeting = meeting
        
        socket = socketManager?.socket(forNamespace: "/copresent-\(meeting.id)-host")

        socket!.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.statusImage.image = NSImage(named: "NSStatusAvailable")
        }

        socket!.on(clientEvent: .disconnect) {data, ack in
            print("socket disconnected")
            self.statusImage.image = NSImage(named: "NSStatusNone")
        }

        socket!.on("next") {data, ack in
            print("NEXT")
            self.runScript(scriptName: "keynote-next")
        }

        socket!.on("prev") {data, ack in
            self.runScript(scriptName: "keynote-prev")
        }

        socket!.on("updateParticipants") {data, ack in
            
            guard let participants = data[0] as? NSArray else { return }
            self.participantHeader.stringValue = "Copresenters (\(participants.count))"
            self.participantField.stringValue = participants.componentsJoined(by: "\n")

        }
        socket!.connect()
   }
    
    @discardableResult
    private func runScript(scriptName:String) -> String{
        
        let statusScript = Bundle.main.url(forResource: scriptName, withExtension: "scpt")!
        
        guard let script = NSAppleScript(contentsOf: statusScript, error: nil)
            else { return "error" }
        
        var error:NSDictionary?
         let output: NSAppleEventDescriptor = script.executeAndReturnError(&error)
        
        if (error != nil) {
            print("error: \(error!)")
            return "error"
        }
        
        return ""

    }
}

