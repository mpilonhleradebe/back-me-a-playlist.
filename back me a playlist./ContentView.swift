import SwiftUI

struct ContentView: View {
    @State var isBackup = false
    @State var isRetrieve = false
    @State var playlistID = ""
    @State var playlistLink = ""
    @State var isIdEntered = false
    @State var isUploading = false
    @State var count = 0.0
    @FocusState var focus: Bool
    @State var keys: Array<String> = []
    
    @State var accessToken: String?
    @State private var playlist: spotifyPlaylist?
    @State private var errorMessage: String?
    @State private var showAlert = false

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("home")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 340, height: 52)
                            .clipped()
                            .saturation(count)
                            .transition(.opacity)
                        Spacer()
                    }
                    
                    if !isBackup {
                        textStyle(Text(greeting()))
                            .opacity(0.5)
                            .padding(.top, 40)
                            .transition(.opacity)
                    } else if isUploading {
                        textStyle(Text("please wait."))
                            .opacity(0.5)
                            .padding(.top, 40)
                            .transition(.opacity)
                    } else {
                        if !isIdEntered {
                            Button(action: {
                                withAnimation {
                                    isBackup = false
                                    isIdEntered = false
                                }
                            }, label: {
                                textStyle(Text("back."))
                                    .padding(.top, 40)
                                    .foregroundStyle(Color("blackblack"))
                                    .transition(.slide)
                            })
                        }
                        
                        if isIdEntered {
                            Button(action: {
                                withAnimation {
                                    isIdEntered = false
                                }
                            }, label: {
                                textStyle(Text("back."))
                                    .padding(.top, 40)
                                    .foregroundStyle(Color("blackblack"))
                            })
                            .padding(.horizontal, -160)
                            .transition(.slide)
                        }
                    }
                    
                    if !isBackup {
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    isBackup = true
                                    isRetrieve = false
                                    count = 0
                                }
                            }, label: {
                                textStyle(Text("backup"))
                                    .foregroundStyle(Color("blackblack"))
                                    .transition(.move(edge: .leading))
                            })
                            
                            textStyle(Text("|"))
                                .opacity(0.5)
                            
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    isRetrieve.toggle()
                                }
                                while count <= 1 {
                                    count += 0.001
                                }
                            }, label: {
                                ZStack {
                                    textStyle(Text("coming soon"))
                                        .foregroundStyle(Color(.yellow))
                                        .opacity(isRetrieve ? 1 : 0)
                                        .padding(.trailing, -100)
                                        .padding(.leading, -40)
                                    Spacer()
                                    HStack {
                                        textStyle(Text("retrieve"))
                                            .foregroundStyle(Color("customGreen"))
                                            .opacity(isRetrieve ? 0 : 1)
                                    }
                                }
                                .transition(.move(edge: .trailing))
                            })
                        }
                        .padding(5)
                    } else {
                        HStack {
                            if !isIdEntered {
                                Rectangle()
                                    .frame(width: 159, height: 33)
                                    .foregroundStyle(Color("customGray"))
                                    .overlay {
                                        HStack {
                                            Spacer()
                                            TextField("paste playlist link", text: $playlistLink)
                                                .font(.custom("HelveticaNeue-Bold", size: 16))
                                                .foregroundStyle(Color("blackblack"))
                                                .focused($focus)
                                                .onSubmit {
                                                    withAnimation {
                                                        playlistID = extractId(from: playlistLink) ?? ""
                                                        if !playlistID.isEmpty {
                                                            isIdEntered = true
                                                            fetchPlaylistData()
                                                        } else {
                                                            // Handle invalid link case
                                                            isIdEntered = false
                                                            print("Invalid playlist link")
                                                        }
                                                    }
                                                }
                                        }
                                        .onAppear {
                                            focus = true
                                        }
                                    }
                                    .transition(.scale)

                            } else if isIdEntered && !isUploading {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(playlist?.name ?? "Loading...")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    
                                    Text(playlist?.description ?? "No description available.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Tracks: \(playlist?.tracks.items.count ?? 0)")
                                        .font(.subheadline)
                                    
                                    Divider()
                                    
                                    ScrollView {
                                        ForEach(playlist?.tracks.items ?? [], id: \.track.name) { item in
                                            VStack(alignment: .leading) {
                                                Text(item.track.name)
                                                    .font(.subheadline)
                                                
                                                Text(item.track.artists.map { $0.name }.joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Divider()
                                            }
                                        }
                                    }
                                    .frame(height: 100)
                                }
                                .padding()
                                .frame(width: 300)
                                .background(Color("customGray"))
                                .cornerRadius(8)
                                .transition(.scale)
                            } else if isUploading {
                                VStack {
//                                    Text("Backing up playlist... \(Int(count * 100))%")
//                                        .padding(.bottom, 5)
                                    Rectangle()
                                        .frame(width: 159, height: 9)
                                        .foregroundStyle(Color("customGray"))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .overlay(
                                            ProgressView(value: count)
                                                .progressViewStyle(LinearProgressViewStyle())
                                                .frame(width: 150)
                                        )
                                        .transition(.opacity)
                                }
                            }
                            
                            if !isIdEntered {
                                Button(action: {
                                    withAnimation {
                                        playlistID = extractId(from: playlistLink) ?? ""
                                        if (!playlistID.isEmpty) {
                                            isIdEntered = true
                                            fetchPlaylistData()
                                        } else {
                                            // Handle invalid link case
                                            isIdEntered = false
                                            print("Invalid playlist link")
                                        }
                                    }
                                }, label: {
                                    Rectangle()
                                        .frame(width: 35, height: 33)
                                        .foregroundStyle(Color("customGray"))
                                        .overlay {
                                            Image(systemName: "icloud.and.arrow.up")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25)
                                                .foregroundStyle(Color("blackblack"))
                                        }
                                })
                                .transition(.scale)
                            } else if isIdEntered && !isUploading {
                                Button(action: {
                                    withAnimation {
                                        isUploading = true
                                        savePlaylistToCSV()
                                    }
                                }, label: {
                                    Rectangle()
                                        .frame(width: 35, height: 33)
                                        .foregroundStyle(Color("customGray"))
                                        .overlay {
                                            Image(systemName: "checkmark.icloud")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25)
                                                .foregroundStyle(Color("blackblack"))
                                        }
                                })
                                .padding(.bottom, 220)
                                .padding(.horizontal, -40)
                                .transition(.scale)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("your memories. in playlists.")
                        .font(.custom("HelveticaNeue-Bold", size: 6))
                        .opacity(0.5)
                        .padding(.bottom, 20)
                }
            }
        }
        .ignoresSafeArea(edges: .all)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Finished backing up"), message: Text("The backup has been completed successfully."), dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: {
            do {
                keys = try returnKeys()
            }
            catch KeysError.dictionaryError {
                print("dictionary error")
            }
            catch KeysError.clientIdError {
                print("client id error")
            }
            catch KeysError.clientSecretError {
                print("client secret error")
            }
            catch {
                print("unexpected error")
            }
            
            Task {
                do {
                    if let token = try await getToken() {
                        self.accessToken = token
                    }
                } catch {
                    print("Error getting token: \(error)")
                }
            }
        })
    }
    
    func textStyle(_ text: Text) -> some View {
        return text
            .font(.custom("HelveticaNeue-Bold", size: 20))
    }
    
    func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting: String
        switch hour {
        case 6..<12:
            greeting = "morning."
        case 12..<17:
            greeting = "afternoon."
        case 17..<21:
            greeting = "evening."
        default:
            greeting = "good.night."
        }
        return greeting
    }
    
    func returnKeys() throws -> Array<String> {
        guard let keysDictionary: [String: Any] = Bundle.main.infoDictionary else {
            throw KeysError.dictionaryError
        }
        
        guard let clientId: String = keysDictionary["<key>clientId</key>"] as? String else {
            throw KeysError.clientIdError
        }
        
        guard let clientSecret: String = keysDictionary["<key>clientSecret</key>"] as? String else {
            throw KeysError.clientSecretError
        }
        
        let keysArray = [clientId, clientSecret]
        return keysArray
    }
    
    func getToken() async throws -> String? {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            throw SpotifyERROR.InvalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let authHeader = "\(keys[0]):\(keys[1])".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(authHeader)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw SpotifyERROR.InvalidRequest
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                return token
            }
        } catch {
            print("Error fetching access token: \(error)")
        }
        return nil
    }
    
    func fetchPlaylistData() {
        Task {
            do {
                if let token = accessToken {
                    if let fetchedPlaylist = try await fetchPlaylist(playlistId: playlistID, accessToken: token) {
                        playlist = fetchedPlaylist
                    }
                }
            } catch {
                print("Error fetching playlist: \(error)")
            }
        }
    }

    func savePlaylistToCSV() {
        guard let playlist = playlist else { return }

        var csvString = "Track Name,Artists\n"
        for item in playlist.tracks.items {
            let trackName = item.track.name.replacingOccurrences(of: ",", with: ";")
            let artists = item.track.artists.map { $0.name }.joined(separator: ";")
            csvString.append("\(trackName),\(artists)\n")
        }

        let fileManager = FileManager.default
        do {
            // Find the Documents directory
            let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            // Append desired filename (e.g., playlist.csv)
            let fileURL = documentsDirectory.appendingPathComponent("playlist.csv")

            // Write to file
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("CSV file saved to: \(fileURL)")

            simulateProgress()
            
        } catch {
            print("Error saving CSV file: \(error)")
        }
    }

    func simulateProgress() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if count < 1.0 {
                count += 0.1
            } else {
                timer.invalidate()
                isUploading = false
                count = 0.0
                showAlert = true
                withAnimation {
                    isBackup = false
                    isIdEntered = false
                }
            }
        }
    }

}

struct spotifyPlaylist: Codable {
    let id: String
    let name: String
    let description: String
    let tracks: Tracks
}

struct Tracks: Codable {
    let items: [TrackItem]
}

struct TrackItem: Identifiable, Codable {
    let id = UUID()
    let track: Track
}

struct Track: Codable {
    let name: String
    let artists: [Artist]
}

struct Artist: Codable {
    let name: String
}

func fetchPlaylist(playlistId: String, accessToken: String) async throws -> spotifyPlaylist? {
    guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)") else {
        throw calls.InvalidPlaylistId
    }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw calls.InvalidResponse
        }
        
        let playlist = try JSONDecoder().decode(spotifyPlaylist.self, from: data)
        return playlist
       
    } catch {
        print("Error fetching playlist: \(error)")
    }
    return nil
}

func extractId(from playlistLink: String) -> String? {
    guard let urlComponents = URLComponents(string: playlistLink) else {
        return nil
    }
    
    let pathComponents = urlComponents.path.split(separator: "/")
    
    if let index = pathComponents.firstIndex(of: "playlist"), index + 1 < pathComponents.count {
        return String(pathComponents[index + 1])
    }
    
    let directComponents = playlistLink.split(separator: "/")
    if let index = directComponents.firstIndex(of: "playlist"), index + 1 < directComponents.count {
        return String(directComponents[index + 1])
    }
    
    return nil
}

enum KeysError: Error {
    case dictionaryError
    case clientIdError
    case clientSecretError
}
enum SpotifyERROR: Error {
    case InvalidUrl
    case InvalidRequest
}
enum calls: Error {
    case InvalidPlaylistId
    case InvalidResponse
}

#Preview {
    ContentView()
}
