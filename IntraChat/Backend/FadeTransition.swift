//
//  FadeTransition.swift
//  IntraChat
//
//  Created by Robyarta on 1/8/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit

import UIKit

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    
    let interactionController = UIPercentDrivenInteractiveTransition()
    
    func navigationController(
        navigationController: UINavigationController,
        interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
    
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationControllerOperation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return SlideTransition(presenting: true)
        case .pop:
            return SlideTransition(presenting: false)
        default:
            return nil
        }
    }
    
}

class SlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 1.0
    var presenting = true
    
    init(presenting: Bool) { self.presenting = presenting }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let fromView = transitionContext.view(forKey: .from) else {return}
        guard let toView = transitionContext.view(forKey: .to) else {return}
        
        containerView.addSubview(fromView)
        containerView.addSubview(toView)
        
        let animation = presenting ?
            CGAffineTransform(translationX: 0, y: -fromView.frame.size.height) :
            CGAffineTransform(translationX: 0, y: fromView.frame.size.height)
        
        toView.transform = !presenting ?
            CGAffineTransform(translationX: 0, y: -fromView.frame.size.height) :
            CGAffineTransform(translationX: 0, y: fromView.frame.size.height)
        
        UIView.animate(withDuration: duration, animations: {
            fromView.transform = animation
            toView.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fromView.transform = .identity
        })
        
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        print("transition end")
    }
    
}


