;;; scad-dbus.el --- Control a running OpenSCAD instance via D-Bus

;; Author:     Len Trigg
;; Maintainer: Len Trigg <lenbok@gmail.com>
;; URL:        https://github.com/Lenbok/scad-dbus/

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; Control a running OpenSCAD instance via the D-Bus interface.
;;
;; Since D-Bus seems to be linux-only, you need to be on linux.
;;
;; Enable DBus in OpenSCAD via:
;;   Preferences-> Features -> input-driver-dbus
;;   Preferences-> Axes -> DBus
;;
;; https://www.gnu.org/software/emacs/manual/html_mono/dbus.html
;;
;; However, as of writing, OpenSCAD seems to have a bug where the D-Bus
;; interface won't execute action commands until after some menu items
;; have manually been selected.  See:
;; https://github.com/openscad/openscad/issues/3367

;;; Code:

(require 'dbus)
(require 'scad-mode)
(require 'hydra)


(defconst scad-dbus-service-name "org.openscad.OpenSCAD"
  "The name of the service that OpenSCAD registers with D-Bus.")


(defun scad-dbus--service-available ()
  "Return non-nil if OpenSCAD is listening on the D-Bus."
  (member scad-dbus-service-name (dbus-list-known-names :session)))

(defun scad-dbus-connected ()
  "Echo to message area whether OpenSCAD is listening on the D-Bus."
  (interactive)
  (if (scad-dbus--service-available)
      (message "OpenSCAD is connected")
    (message "OpenSCAD is not connected")))

(defun scad-dbus--call-method (method &rest args)
  "Call the OpenSCAD method METHOD with ARGS over D-Bus."
  (apply 'dbus-call-method
    :session                             ; use the session (not system) bus
    scad-dbus-service-name               ; service name
    "/org/openscad/OpenSCAD/Application" ; path name
    "org.openscad.OpenSCAD"              ; interface name
    method args))

(defun scad-dbus--call-action (name)
  "Call the OpenSCAD method \"action\" with NAME over D-Bus."
  (scad-dbus--call-method "action" name))


;; Use this to ask OpenSCAD for get the list of available actions
(defun scad-dbus-list-actions ()
  "List OpenSCAD action methods to a help buffer."
  (interactive)
  (with-help-window "*scad-dbus-output*"
    (with-current-buffer "*scad-dbus-output*"
      (insert "** OpenSCAD DBus Action Commands **\n"
              (mapconcat 'identity
                         (scad-dbus--call-method "getActions")
                         "\n")))))

;; Macros to define interactive commands binding to dbus method calls

(defmacro scad-dbus--3-axis-command (command method idx amount)
  (fset command
        (list `lambda `() `(interactive)
              (append `(scad-dbus--call-method ,method)
                      (make-list (- idx 1) 0.0)
                      (list amount)
                      (make-list (- 3 idx) 0.0)))))
(defmacro scad-dbus--1-axis-command (command method amount)
  (fset command
        (list `lambda `() `(interactive)
              (append `(scad-dbus--call-method ,method)
                      (list amount)))))
(defmacro scad-dbus--action-command (command method)
  (fset command
        (list `lambda `() `(interactive)
              `(scad-dbus--call-action ,method))))
;(macroexpand `(scad-dbus--3-axis-command scad-call-rotx+ "rotate" 1 5.0))


;; Define commands for direct camera control
(scad-dbus--3-axis-command scad-dbus-rotx+ "rotate" 1 5.0)
(scad-dbus--3-axis-command scad-dbus-rotx- "rotate" 1 -5.0)
(scad-dbus--3-axis-command scad-dbus-roty+ "rotate" 2 5.0)
(scad-dbus--3-axis-command scad-dbus-roty- "rotate" 2 -5.0)
(scad-dbus--3-axis-command scad-dbus-rotz+ "rotate" 3 5.0)
(scad-dbus--3-axis-command scad-dbus-rotz- "rotate" 3 -5.0)
(scad-dbus--3-axis-command scad-dbus-trnsx+ "translate" 1 5.0)
(scad-dbus--3-axis-command scad-dbus-trnsx- "translate" 1 -5.0)
(scad-dbus--3-axis-command scad-dbus-trnsy+ "translate" 2 5.0)
(scad-dbus--3-axis-command scad-dbus-trnsy- "translate" 2 -5.0)
(scad-dbus--3-axis-command scad-dbus-trnsz+ "translate" 3 5.0)
(scad-dbus--3-axis-command scad-dbus-trnsz- "translate" 3 -5.0)
(scad-dbus--1-axis-command scad-dbus-zoom+ "zoom" 40.0)
(scad-dbus--1-axis-command scad-dbus-zoom- "zoom" -40.0)

;; Commands from File menu
(scad-dbus--action-command scad-dbus-export-stl "fileActionExportSTL")
(scad-dbus--action-command scad-dbus-export-image "fileActionExportImage")
(scad-dbus--action-command scad-dbus-quit "fileActionQuit")

;; Commands from Design menu
(scad-dbus--action-command scad-dbus-render "designActionRender")
(scad-dbus--action-command scad-dbus-preview "designActionPreview")

;; Commands from View menu
(scad-dbus--action-command scad-dbus-view-top "viewActionTop")
(scad-dbus--action-command scad-dbus-view-front "viewActionFront")
(scad-dbus--action-command scad-dbus-view-diagonal "viewActionDiagonal")
(scad-dbus--action-command scad-dbus-view-reset "viewActionResetView")
(scad-dbus--action-command scad-dbus-view-all "viewActionViewAll")
(scad-dbus--action-command scad-dbus-view-center "viewActionCenter")
(scad-dbus--action-command scad-dbus-view-zoom-in "viewActionZoomIn")
(scad-dbus--action-command scad-dbus-view-zoom-out "viewActionZoomOut")
(scad-dbus--action-command scad-dbus-view-console "viewActionHideConsole")
(scad-dbus--action-command scad-dbus-view-axes "viewActionShowAxes")


(defhydra hydra-scad-dbus (:foreign-keys warn)
  "
 View^^                       ^^^^^^^^                Extras^^
 [_a_] all        [_h_][_j_][_k_][_l_] rotate         [_xc_] console    [_xi_] export image
 [_c_] center     [_H_][_J_][_K_][_L_] translate      [_xa_] axes       [_xs_] export STL
 [_t_] top              ^^^^[_u_][_i_] zoom           [_xp_] preview
 [_f_] front                  ^^^^^^^^                [_xr_] render
 [_d_] diagonal            ^^^^^^[_r_] reset
"
  ("t" scad-dbus-view-top)
  ("f" scad-dbus-view-front)
  ("d" scad-dbus-view-diagonal)
  ("c" scad-dbus-view-center)
  ("a" scad-dbus-view-all)
  ("r" scad-dbus-view-reset)

  ("h" scad-dbus-rotz-)
  ("j" scad-dbus-rotx+)
  ("k" scad-dbus-rotx-)
  ("l" scad-dbus-rotz+)

  ("H" scad-dbus-trnsx-)
  ("J" scad-dbus-trnsz-)
  ("K" scad-dbus-trnsz+)
  ("L" scad-dbus-trnsx+)

  ("i" scad-dbus-zoom+)
  ("u" scad-dbus-zoom-)

  ("xc" scad-dbus-view-console)
  ("xa" scad-dbus-view-axes)
  ("xp" scad-dbus-render)
  ("xr" scad-dbus-render)
  ("xs" scad-dbus-export-stl)
  ("xi" scad-dbus-export-image)

  ("q" nil "quit"))

(define-key scad-mode-map (kbd "C-c o") 'hydra-scad-dbus/body)

(provide 'scad-dbus)
;;; scad-dbus.el ends here
