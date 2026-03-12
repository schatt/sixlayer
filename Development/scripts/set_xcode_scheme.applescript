-- Set the active scheme in an Xcode window.
-- Usage:
--   Run with no args: prompts for scheme (and optionally window).
--   Run with scheme name: osascript set_xcode_scheme.applescript "SLF-iOS-AllTests"
--     Tries the frontmost window first; if the scheme is not found there, searches other Xcode
--     windows and brings the one that has the scheme to front, then sets it. No need to click
--     the target window first.
--   Run with scheme and window: osascript set_xcode_scheme.applescript "SLF-iOS-AllTests" 2
--     (window 2 = second window; 1 = frontmost)
--   Run with scheme and window title fragment: osascript set_xcode_scheme.applescript "SLF-iOS-AllTests" "SixLayer"
--     (brings first window whose title contains "SixLayer" to front, then sets scheme)

on run argv
	if (count of argv) = 0 then
		return runInteractive()
	else if (count of argv) = 1 then
		set schemeName to item 1 of argv
		set windowSelector to "front"
		return setSchemeInXcode(schemeName, windowSelector)
	else
		set schemeName to item 1 of argv
		set secondArg to item 2 of argv
		-- If second arg looks like a path (contains "/" or ":"), treat it as a workspace/project path
		-- so we can force the correct window by opening that file first.
		if (secondArg contains "/") or (secondArg contains ":") then
			return setSchemeForWorkspace(schemeName, secondArg)
		else
			set windowSelector to secondArg
			return setSchemeInXcode(schemeName, windowSelector)
		end if
	end if
end run

on runInteractive()
	tell application "Xcode" to activate
	delay 0.3
	tell application "Xcode"
		if (count of documents) = 0 then
			display alert "No project open" message "Open a project or workspace in Xcode first."
			return "NO_DOCUMENT"
		end if
		set doc to active workspace document
		set schemeList to name of every scheme in doc
		set chosenScheme to choose from list schemeList with prompt "Choose scheme for this window:" default items (item 1 of schemeList)
		if chosenScheme is false then
			return "CANCELLED"
		end if
		set schemeName to item 1 of chosenScheme
	end tell
	return setSchemeInXcode(schemeName, "front")
end runInteractive

on setSchemeInXcode(schemeName, windowSelector)
	tell application "Xcode" to activate
	delay 0.2

	-- Bring the chosen window to front so "active workspace document" is the right one
	if windowSelector is not "front" then
		tell application "System Events"
			tell process "Xcode"
				set windowCount to count of windows
				if windowCount = 0 then
					return "NO_WINDOWS"
				end if
				try
					set sel to windowSelector as integer
					-- sel is 1-based: 1 = front, 2 = second, etc.
					if sel > 1 and sel ≤ windowCount then
						my bringWindowToFront(window sel)
						delay 0.2
					end if
				on error
					-- Assume it's a title fragment
					repeat with i from 1 to windowCount
						set win to window i
						set winName to name of win
						if winName contains (windowSelector as text) then
							my bringWindowToFront(win)
							delay 0.2
							exit repeat
						end if
					end repeat
				end try
			end tell
		end tell
	else
		-- "front": try current window first; if scheme not found, search other windows
		set tryResult to trySetSchemeInActiveDocument(schemeName)
		if tryResult is not "SCHEME_NOT_FOUND" then
			return tryResult
		end if
		tell application "System Events"
			tell process "Xcode"
				set windowCount to count of windows
				if windowCount < 2 then
					return "SCHEME_NOT_FOUND"
				end if
				repeat with i from 2 to windowCount
					my bringWindowToFront(window i)
					delay 0.2
					set tryResult to trySetSchemeInActiveDocument(schemeName)
					if tryResult is not "SCHEME_NOT_FOUND" then
						return tryResult
					end if
				end repeat
			end tell
		end tell
		return "SCHEME_NOT_FOUND"
	end if

	return trySetSchemeInActiveDocument(schemeName)
end setSchemeInXcode

-- Open a specific workspace/project file in Xcode (if needed), bring it to the front, then set the scheme.
-- This forces the "active workspace document" to be the one at workspacePath, avoiding ambiguity when
-- multiple unrelated projects are open.
on setSchemeForWorkspace(schemeName, workspacePath)
	set wsFile to POSIX file workspacePath
	tell application "Xcode"
		activate
		open wsFile
	end tell
	-- Give Xcode a moment to open/focus the workspace, then set scheme in the frontmost window.
	delay 0.5
	return setSchemeInXcode(schemeName, "front")
end setSchemeForWorkspace

-- Try to set the scheme in Xcode's current active workspace document. Returns "OK", "NO_DOCUMENT", or "SCHEME_NOT_FOUND".
on trySetSchemeInActiveDocument(schemeName)
	tell application "Xcode"
		if (count of documents) = 0 then
			return "NO_DOCUMENT"
		end if
		set doc to active workspace document
		set allSchemes to schemes in doc
		repeat with s in allSchemes
			if (name of s as text) is equal to (schemeName as text) then
				set active scheme of doc to s
				return "OK"
			end if
		end repeat
		return "SCHEME_NOT_FOUND"
	end tell
end trySetSchemeInActiveDocument

-- Bring an Xcode window to front. Tries "set index to 1"; on error (e.g. -10006) clicks the window to focus it.
on bringWindowToFront(win)
	tell application "System Events"
		tell process "Xcode"
			try
				set index of win to 1
			on error
				-- Fallback: click inside the window to focus it (avoids -10006 in some environments)
				set pos to position of win
				set sz to size of win
				set clickX to (item 1 of pos) + (item 1 of sz) / 2
				set clickY to (item 2 of pos) + (item 2 of sz) / 2
				click at {clickX, clickY}
			end try
		end tell
	end tell
end bringWindowToFront
