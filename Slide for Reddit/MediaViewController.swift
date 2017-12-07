//
//  MediaViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/28/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import MaterialComponents.MaterialProgressView

class MediaViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    var subChanged = false
    
    var link:RSubmission!
    
    public func setLink(lnk: RSubmission, shownURL: URL?, lq: Bool, saveHistory: Bool){ //lq is should load lq and did load lq
        if(saveHistory){
            History.addSeen(s: lnk)
        }
        self.link = lnk
        if(lq){
            doShow(url: link.url!, lq: shownURL)
        } else {
            doShow(url: link.url!)
        }
    }
        
    func getControllerForUrl(baseUrl: URL, lq: URL? = nil) -> UIViewController? {
        print(baseUrl )
        contentUrl = baseUrl
        var url = contentUrl?.absoluteString
        if(shouldTruncate(url: contentUrl!)){
            let content = contentUrl?.absoluteString
            contentUrl = URL.init(string: (content?.substring(to: (content?.characters.index(of: "."))!))!)
        }
        let type = ContentType.getContentType(baseUrl: contentUrl!)
        
        if(type == ContentType.CType.ALBUM && SettingValues.internalAlbumView){
            print("Showing album")
            return AlbumViewController.init(urlB: contentUrl!)
        } else if (contentUrl != nil && ContentType.displayImage(t: type) && SettingValues.internalImageView || (type == .GIF && SettingValues.internalGifView && (ContentType.isGifLoadInstantly(uri: link.url!) || !link.videoPreview.isEmpty())) || type == .STREAMABLE || type == .VID_ME || (type == ContentType.CType.VIDEO && SettingValues.internalYouTube)) {
            if(!ContentType.isGifLoadInstantly(uri: link.url!)){
                contentUrl = URL.init(string: link.videoPreview)
            }
            print(link.videoPreview)
            return SingleContentViewController.init(url: contentUrl!, lq: lq)
        } else if(type == ContentType.CType.LINK || type == ContentType.CType.NONE){
            let web = WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
            return web
        } else if(type == ContentType.CType.REDDIT){
            return RedditLink.getViewControllerForURL(urlS: contentUrl!)
        }
        return WebsiteViewController(url: baseUrl, subreddit: link == nil ? "" : link.subreddit)
    }
    
    var contentUrl:URL?

    public func shouldTruncate(url: URL) -> Bool {
        let path = url.path
        return !ContentType.isGif(uri: url) && !ContentType.isImage(uri: url) && path.contains(".");
    }
    
    func showSpoiler(_ string: String){
        let m = string.capturedGroups(withRegex: "\\[\\[s\\[(.*?)\\]s\\]\\]")
        let controller = UIAlertController.init(title: "Spoiler", message: m[0][1], preferredStyle: .alert)
        controller.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func doShow(url: URL, lq: URL? = nil){
        print(url)
        contentUrl = url
        var spoiler = ContentType.isSpoiler(uri: url)
        if(spoiler){
            let controller = UIAlertController.init(title: "Spoiler", message: url.absoluteString, preferredStyle: .alert)
            present(controller, animated: true, completion: nil)
        } else {
        let controller = getControllerForUrl(baseUrl: url, lq: lq)!
        if( controller is AlbumViewController){
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        } else if(controller is SingleContentViewController){
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        } else {
                if(UIScreen.main.traitCollection.userInterfaceIdiom == .pad ){
                    let navigationController = TapBehindModalViewController(rootViewController: controller)
                    navigationController.modalPresentationStyle = .pageSheet
                    navigationController.modalTransitionStyle = .crossDissolve
                    present(navigationController, animated: true, completion: nil)
                } else {
                    show(controller, sender: self)
                }
        }
        navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    var color: UIColor?
    
    func setBarColors(color: UIColor){
        self.color = color
        setNavColors()
    }
    
    func setNavColors(){
        if(navigationController != nil){
            navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.barTintColor = color
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage()
        setNavColors()
        navigationController?.isToolbarHidden = true
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return LeftTransition()
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let leftTransiton = LeftTransition()
        leftTransiton.dismiss = true
        return leftTransiton
    }
    

}

extension URL {
    
    var queryDictionary: [String: String] {
        var queryDictionary = [String: String]()
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return queryDictionary }
        queryItems.forEach { queryDictionary[$0.name] = $0.value }
        return queryDictionary
    }
    
}
