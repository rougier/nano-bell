;;; nano-bell.el --- N Λ N O Bell -*- lexical-binding: t -*-

;; Copyright (C) 2021 Free Software Foundation, Inc.

;; Maintainer: Nicolas P. Rougier <Nicolas.Rougier@inria.fr>
;; URL: https://github.com/rougier/nano-bell
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; N Λ N O Bell is a non intrusive visual bell that flash and fade-out
;; the header line. The actual bell is a child frame that is overlaid on
;; top of the header line.

;; The size and position is controlled by the `nano-bell-update` function
;; that you can rewrite to adapt the size and position to your liking,
;; for example if you want to flash the mode line instead or having
;; something even less intrusive.

;; The duration of the flash is controled by the `nano-bell-duration`
;; variable and the number of animation frames is controlled by the
;; variale `nano-bell-steps`. Color of the flash is defined by
;; `nano-bell-color`.
;;
;; Usage example:
;;
;; M-: (setq ring-bell-function 'nano-bell)
;;
;;; NEWS:
;;
;; Version 0.1
;; - First version
;;
;;; Code
(defgroup nano nil
  "N Λ N O"
  :group 'convenience)

(defgroup nano-bell nil
  "N Λ N O Bell"
  :group 'nano)

(defcustom nano-bell-duration 0.25
  "Duration (in seconds) of the bell animation."
  :group 'nano-bell)

(defcustom nano-bell-steps 25
  "Number of steps for the bell animation."
  :group 'nano-bell)

(defcustom nano-bell-color (face-background 'nano-popout-i)
  "Backgroud color of the bell frame"
  :group 'nano-bell)

(defun nano-bell-update (parent frame)
  "Update nano frame position & size. You can safely advice this function. "

  (let* ((width (frame-pixel-width parent))
         (height (frame-pixel-height parent)))
    (modify-frame-parameters frame `((top . 24)
                                     (left . 24)
                                     (background-color . ,nano-bell-color)
                                     (height . (text-pixels . 26))
                                     (width  . (text-pixels . ,(- width 48)))))))

(defun nano-bell-root-frame (frame)
  (let* ((root frame)
         (frame (frame-parameter frame 'parent-frame)))
    (while frame
      (setq root frame)
      (setq frame (frame-parameter frame 'parent-frame)))
    root))

(defun nano-bell ()
  "Set the header line to 'nano-critical face and fade it to fully transparent.
Animation lasts for NANO-BELL-DURATION using NANO-BELL-STEPS steps."
  
  ;; First cancel any ongoing timer
  (let* ((parent (nano-bell-root-frame (window-frame)))
         (frame (frame-parameter parent 'nano-bell-frame)) 
         (timer (if frame (frame-parameter frame 'nano-bell-timer))))
    (when timer
      (cancel-timer timer)
      (modify-frame-parameters frame `((nano-bell-timer . nil)))))

  ;; Create bell frame if necessary
  (let* ((parent (nano-bell-root-frame (window-frame)))
         (frame (frame-parameter parent 'nano-bell-frame))
         (width (frame-pixel-width))
         (height (frame-pixel-height))
         (selected (selected-frame))
         (timer nil)
         (frame (or frame
                    (make-frame `((parent-frame . ,parent)
                                  (no-accept-focus . t)
                                  (min-width  . 1)
                                  (min-height . 1)
                                  (internal-border-width . 0)
                                  (vertical-scroll-bars . nil)
                                  (horizontal-scroll-bars . nil)
                                  (left-fringe . 0)
                                  (right-fringe . 0)
                                  (keep-ratio . nil)
                                  (user-position . nil)
                                  (user-size . nil)
                                  (menu-bar-lines . 0)
                                  (tool-bar-lines . 0)
                                  (line-spacing . 0)
                                  (desktop-dont-save . t)
                                  (unsplittable . t)
                                  (delete-before t)
                                  (no-other-frame . nil)
                                  (undecorated . t)
                                  (pixelwise . t)
                                  (modeline . nil)
                                  (visibility . nil)
                                  (cursor-type . nil)
                                  (minibuffer . nil))))))

    (modify-frame-parameters parent `((nano-bell-frame . ,frame)))
    (nano-bell-update parent frame)
    (modify-frame-parameters frame `((alpha . 1.0)))
    (select-frame frame)
    (switch-to-buffer "*nano-bell*")
    (setq header-line-format nil)
    (setq mode-line-format nil)
    (select-frame selected)
    (make-frame-visible frame)
    ;; (setq nano-bell--alpha 1.0)
    (setq timer (run-with-timer 0 (/ nano-bell-duration nano-bell-steps) 
                                 'nano-bell--fade-out frame))
    (modify-frame-parameters frame `((nano-bell-timer . ,timer)))))
    

(defun nano-bell--fade-out (frame)
  "Fade out the nano bell frame"

  (let* ((timer (frame-parameter frame 'nano-bell-timer))
         (alpha (frame-parameter frame 'alpha))
         (alpha (- alpha (/ 1.0 nano-bell-steps))))
    (if (> alpha 0)
        (set-frame-parameter frame 'alpha alpha)
      (progn
        (make-frame-invisible frame)
        (if timer 
            (cancel-timer timer))
        (modify-frame-parameters frame `((nano-bell-timer . nil)))))))


(provide 'nano-bell)
;;; nano-bell.el ends here
