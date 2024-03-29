import UIKit

class ViewController: UIViewController, SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, SPTAppRemoteUserAPIDelegate {
    
    fileprivate let SpotifyClientID = "b2fba06d5d054c589fe54a5ce19b9855"
    fileprivate let SpotifyRedirectURI = URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    
    lazy var configuration = SPTConfiguration(
        clientID: self.SpotifyClientID,
        redirectURL: self.SpotifyRedirectURI
    )
    
    lazy var sessionManager: SPTSessionManager = {
        if  let tokenSwapURL = URL(string: "https://bald-bedbug.glitch.me/api/token"),
            let tokenRefreshURL = URL(string: "https://bald-bedbug.glitch.me/api/refresh_token") {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    fileprivate var lastPlayerState: SPTAppRemotePlayerState?
    
    // MARK: - Subviews
    fileprivate lazy var connectLabel: UILabel = {
        let label = UILabel()
        label.text = "Connect your Spotify account"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    fileprivate lazy var connectButton = ConnectButton(title: "CONNECT")
    fileprivate lazy var disconnectButton = ConnectButton(title: "DISCONNECT")
    
    fileprivate lazy var pauseAndPlayButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapPauseOrPlay), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate lazy var nextButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapSkipNext), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate lazy var prevButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapSkipPrev), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var trackLabel: UILabel = {
        let trackLabel = UILabel()
        trackLabel.translatesAutoresizingMaskIntoConstraints = false
        trackLabel.textAlignment = .center
        return trackLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        view.addSubview(connectLabel)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        view.addSubview(imageView)
        view.addSubview(trackLabel)
        view.addSubview(pauseAndPlayButton)
        view.addSubview(nextButton)
        view.addSubview(prevButton)
        
        let constant: CGFloat = 16.0
        
        connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        disconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        disconnectButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        
        connectLabel.centerXAnchor.constraint(equalTo: connectButton.centerXAnchor).isActive = true
        connectLabel.bottomAnchor.constraint(equalTo: connectButton.topAnchor, constant: -constant).isActive = true
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 64).isActive = true
        imageView.bottomAnchor.constraint(equalTo: trackLabel.topAnchor, constant: -constant).isActive = true
        
        trackLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        trackLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: constant).isActive = true
        trackLabel.bottomAnchor.constraint(equalTo: connectLabel.topAnchor, constant: -constant).isActive = true
        
        pauseAndPlayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pauseAndPlayButton.topAnchor.constraint(equalTo: trackLabel.bottomAnchor, constant: constant).isActive = true
        pauseAndPlayButton.widthAnchor.constraint(equalToConstant: 50)
        pauseAndPlayButton.heightAnchor.constraint(equalToConstant: 50)
        pauseAndPlayButton.sizeToFit()
        
        nextButton.leftAnchor.constraint(equalTo: pauseAndPlayButton.rightAnchor).isActive = true
        nextButton.topAnchor.constraint(equalTo: trackLabel.bottomAnchor, constant: constant).isActive = true
        nextButton.widthAnchor.constraint(equalToConstant: 50)
        nextButton.heightAnchor.constraint(equalToConstant: 50)
        nextButton.sizeToFit()
        nextButton.setImage(UIImage(named: "play"), for: .normal)
        
        prevButton.rightAnchor.constraint(equalTo: pauseAndPlayButton.leftAnchor).isActive = true
        prevButton.topAnchor.constraint(equalTo: trackLabel.bottomAnchor, constant: constant).isActive = true
        prevButton.widthAnchor.constraint(equalToConstant: 50)
        prevButton.heightAnchor.constraint(equalToConstant: 50)
        prevButton.sizeToFit()
        prevButton.setImage(UIImage(named: "play"), for: .normal)
        
        connectButton.sizeToFit()
        disconnectButton.sizeToFit()
        
        connectButton.addTarget(self, action: #selector(didTapConnect(_:)), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(didTapDisconnect(_:)), for: .touchUpInside)
        
        updateViewBasedOnConnected()
    }
    
    func update(playerState: SPTAppRemotePlayerState) {
        if lastPlayerState?.track.uri != playerState.track.uri {
            fetchArtwork(for: playerState.track)
        }
        lastPlayerState = playerState
        trackLabel.text = playerState.track.name
        if playerState.isPaused {
            pauseAndPlayButton.setImage(UIImage(named: "play"), for: .normal)
        } else {
            pauseAndPlayButton.setImage(UIImage(named: "pause"), for: .normal)
        }
    }
    
    func updateViewBasedOnConnected() {
        if (appRemote.isConnected) {
            connectButton.isHidden = true
            disconnectButton.isHidden = false
            connectLabel.isHidden = true
            imageView.isHidden = false
            trackLabel.isHidden = false
            pauseAndPlayButton.isHidden = false
            nextButton.isHidden = false
            prevButton.isHidden = false
        } else {
            disconnectButton.isHidden = true
            connectButton.isHidden = false
            connectLabel.isHidden = false
            imageView.isHidden = true
            trackLabel.isHidden = true
            pauseAndPlayButton.isHidden = true
            nextButton.isHidden = true
            prevButton.isHidden = true
        }
    }
    
    func fetchArtwork(for track:SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                self?.imageView.image = image
            }
        })
    }
    
    func fetchPlayerState() {
        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
        print("User " + sessionManager.session!.accessToken)
    }
    
    // MARK: - Actions
    @objc func didTapPauseOrPlay(_ button: UIButton) {
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
        } else {
            appRemote.playerAPI?.pause(nil)
        }
    }
    
    @objc func didTapSkipNext(_ button: UIButton) {
        appRemote.playerAPI?.skip(toNext: nil)
    }
    
    @objc func didTapSkipPrev(_ button: UIButton) {
        appRemote.playerAPI?.skip(toPrevious: nil)
    }
    
    @objc func didTapDisconnect(_ button: UIButton) {
        if (appRemote.isConnected) {
            appRemote.disconnect()
        }
    }
    
    @objc func didTapConnect(_ button: UIButton) {
        /*
         Scopes let you specify exactly what types of data your application wants to
         access, and the set of scopes you pass in your call determines what access
         permissions the user is asked to grant.
         For more information, see https://developer.spotify.com/web-api/using-scopes/.
         */
        let scope: SPTScope = [.appRemoteControl, .playlistReadPrivate]
        
        if #available(iOS 11, *) {
            // Use this on iOS 11 and above to take advantage of SFAuthenticationSession
            sessionManager.initiateSession(with: scope, options: .clientOnly)
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            sessionManager.initiateSession(with: scope, options: .clientOnly, presenting: self)
        }
    }
    
    
    // MARK: - SPTSessionManagerDelegate
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }
    
    // MARK: - SPTAppRemoteDelegate
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        NSLog(">:?")
        updateViewBasedOnConnected()
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
        fetchPlayerState()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        updateViewBasedOnConnected()
        lastPlayerState = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        updateViewBasedOnConnected()
        lastPlayerState = nil
    }
    
    // MARK: - SPTAppRemoteUserAPIDelegate
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
        
    }
    
    // MARK: - SPTAppRemotePlayerAPIDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        update(playerState: playerState)
    }
    
    // MARK: - Private Helpers
    fileprivate func presentAlertController(title: String, message: String, buttonTitle: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        controller.addAction(action)
        present(controller, animated: true)
    }
}
