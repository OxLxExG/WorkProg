{* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is DScintilla.pas
 *
 * The Initial Developer of the Original Code is Krystian Bigaj.
 *
 * Portions created by the Initial Developer are Copyright (C) 2010-2015
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * - Michal Gajek
 * - Marko Njezic
 * - Michael Staszewski
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** *}

unit DScintilla;

interface

uses
  DScintillaCustom, DScintillaTypes, DScintillaUtils,

  Windows, SysUtils, Classes, Messages, Graphics, Controls, Math;

type

{ TDScintilla }

  // XE2+
  {$IF CompilerVersion >= 23}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  {$IFEND}

  TDScintilla = class(TDScintillaCustom)
  private
    FHelper: TDSciHelper;
    FLines: TDSciLines;

    FInitDefaultsDelayed: Boolean;

    FOnInitDefaults: TNotifyEvent;
    FOnStoreDocState: TNotifyEvent;
    FOnRestoreDocState: TNotifyEvent;

    FOnChange: TNotifyEvent;
    FOnSCNotificationEvent: TDSciNotificationEvent;

    FOnUpdateUI: TDSciUpdateUIEvent;
    FOnSavePointReached: TDSciSavePointReachedEvent;
    FOnZoom: TDSciZoomEvent;
    FOnUserListSelection: TDSciUserListSelectionEvent;
    FOnUserListSelection2: TDSciUserListSelection2Event;
    FOnDwellEnd: TDSciDwellEndEvent;
    FOnPainted: TDSciPaintedEvent;
    FOnModifyAttemptRO: TDSciModifyAttemptROEvent;
    FOnAutoCCharDeleted: TDSciAutoCCharDeletedEvent;
    FOnAutoCCancelled: TDSciAutoCCancelledEvent;
    FOnModified: TDSciModifiedEvent;
    FOnModified2: TDSciModified2Event;
    FOnStyleNeeded: TDSciStyleNeededEvent;
    FOnSavePointLeft: TDSciSavePointLeftEvent;
    FOnIndicatorRelease: TDSciIndicatorReleaseEvent;
    FOnNeedShown: TDSciNeedShownEvent;
    FOnMacroRecord: TDSciMacroRecordEvent;
    FOnCharAdded: TDSciCharAddedEvent;
    FOnCallTipClick: TDSciCallTipClickEvent;
    FOnHotSpotClick: TDSciHotSpotClickEvent;
    FOnMarginClick: TDSciMarginClickEvent;
    FOnHotSpotDoubleClick: TDSciHotSpotDoubleClickEvent;
    FOnHotSpotReleaseClick: TDSciHotSpotReleaseClickEvent;
    FOnDwellStart: TDSciDwellStartEvent;
    FOnIndicatorClick: TDSciIndicatorClickEvent;
    FOnAutoCSelection: TDSciAutoCSelectionEvent;

    procedure SetLines(const Value: TDSciLines);

  protected
    procedure CreateWnd; override;
    procedure Loaded; override;

    /// <summary>Initializes Scintilla control after creating or recreating window</summary>
    procedure InitDefaults; virtual;
    procedure DoInitDefaults;

    /// <summary>Handles SCEN_CHANGE message from Scintilla</summary>
    procedure CNCommand(var AMessage: TWMCommand); message CN_COMMAND;

    /// <summary>Handles notification messages from Scintilla</summary>
    procedure CNNotify(var AMessage: TWMNotify); message CN_NOTIFY; // Thanks to Marko Njezic there is no need to patch Scintilla anymore :)

    procedure DoNeedShown(const ASCNotification: TDSciSCNotification); virtual;
    function DoSCNotification(const ASCNotification: TDSciSCNotification): Boolean; virtual;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  public

    // -------------------------------------------------------------------------
    // Scintilla methods -------------------------------------------------------
    // -------------------------------------------------------------------------
{$REGION 'Scintilla methods '}
    /// <summary>Add text to the document at current position.</summary>
    procedure AddText(const AText: UnicodeString);

    /// <summary>Add array of cells to document.</summary>
    procedure AddStyledText(const ACells: TDSciCells);

    /// <summary>Insert string at a position.</summary>
    procedure InsertText(APos: Integer; const AText: UnicodeString);

    /// <summary>Change the text that is being inserted in response to SC_MOD_INSERTCHECK</summary>
    procedure ChangeInsertion(const AText: UnicodeString);

    /// <summary>Delete all text in the document.</summary>
    procedure ClearAll;

    /// <summary>Delete a range of text in the document.</summary>
    procedure DeleteRange(APos: Integer; ADeleteLength: Integer);

    /// <summary>Set all style bytes to 0, remove all folding information.</summary>
    procedure ClearDocumentStyle;

    /// <summary>Redoes the next action on the undo history.</summary>
    procedure Redo;

    /// <summary>Select all the text in the document.</summary>
    procedure SelectAll;

    /// <summary>Remember the current position in the undo history as the position
    /// at which the document was saved.</summary>
    procedure SetSavePoint;

    /// <summary>Retrieve a buffer of cells.
    /// Returns the number of bytes in the buffer not including terminating NULs.</summary>
    function GetStyledText(AStart, AEnd: Integer): TDSciCells;

    /// <summary>Are there any redoable actions in the undo history?</summary>
    function CanRedo: Boolean;

    /// <summary>Retrieve the line number at which a particular marker is located.</summary>
    function MarkerLineFromHandle(AHandle: Integer): Integer;

    /// <summary>Delete a marker.</summary>
    procedure MarkerDeleteHandle(AHandle: Integer);

    /// <summary>Find the position from a point within the window.</summary>
    function PositionFromPoint(AX: Integer; AY: Integer): Integer;

    /// <summary>Find the position from a point within the window but return
    /// INVALID_POSITION if not close to text.</summary>
    function PositionFromPointClose(AX: Integer; AY: Integer): Integer;

    /// <summary>Set caret to start of a line and ensure it is visible.</summary>
    procedure GotoLine(ALine: Integer);

    /// <summary>Set caret to a position and ensure it is visible.</summary>
    procedure GotoPos(APos: Integer);

    /// <summary>Retrieve the text of the line containing the caret.
    /// Returns the index of the caret on the line.</summary>
    function GetCurLine(var AText: UnicodeString): Integer;

    /// <summary>Convert all line endings in the document to one mode.</summary>
    procedure ConvertEOLs(AEolMode: Integer);

    /// <summary>Set the current styling position to pos and the styling mask to mask.
    /// The styling mask can be used to protect some bits in each styling byte from modification.</summary>
    procedure StartStyling(APos: Integer; AMask: Integer);

    /// <summary>Change style from current styling position for length characters to a style
    /// and move the current styling position to after this newly styled segment.</summary>
    procedure SetStyling(ALength: Integer; AStyle: Integer);

    /// <summary>Set the symbol used for a particular marker number.</summary>
    procedure MarkerDefine(AMarkerNumber: Integer; AMarkerSymbol: Integer);

    /// <summary>Set the foreground colour used for a particular marker number.</summary>
    procedure MarkerSetFore(AMarkerNumber: Integer; AFore: TColor);

    /// <summary>Set the background colour used for a particular marker number.</summary>
    procedure MarkerSetBack(AMarkerNumber: Integer; ABack: TColor);

    /// <summary>Set the background colour used for a particular marker number when its folding block is selected.</summary>
    procedure MarkerSetBackSelected(AMarkerNumber: Integer; ABack: TColor);

    /// <summary>Enable/disable highlight for current folding bloc (smallest one that contains the caret)</summary>
    procedure MarkerEnableHighlight(AEnabled: Boolean);

    /// <summary>Add a marker to a line, returning an ID which can be used to find or delete the marker.</summary>
    function MarkerAdd(ALine: Integer; AMarkerNumber: Integer): Integer;

    /// <summary>Delete a marker from a line.</summary>
    procedure MarkerDelete(ALine: Integer; AMarkerNumber: Integer);

    /// <summary>Delete all markers with a particular number from all lines.</summary>
    procedure MarkerDeleteAll(AMarkerNumber: Integer);

    /// <summary>Get a bit mask of all the markers set on a line.</summary>
    function MarkerGet(ALine: Integer): Integer;

    /// <summary>Find the next line at or after lineStart that includes a marker in mask.
    /// Return -1 when no more lines.</summary>
    function MarkerNext(ALineStart: Integer; AMarkerMask: Integer): Integer;

    /// <summary>Find the previous line before lineStart that includes a marker in mask.</summary>
    function MarkerPrevious(ALineStart: Integer; AMarkerMask: Integer): Integer;

    /// <summary>Define a marker from a pixmap.</summary>
    procedure MarkerDefinePixmap(AMarkerNumber: Integer; const APixmap: TBytes);

    /// <summary>Add a set of markers to a line.</summary>
    procedure MarkerAddSet(ALine: Integer; ASet: Integer);

    /// <summary>Set the alpha used for a marker that is drawn in the text area, not the margin.</summary>
    procedure MarkerSetAlpha(AMarkerNumber: Integer; AAlpha: Integer);

    /// <summary>Clear all the styles and make equivalent to the global default style.</summary>
    procedure StyleClearAll;

    /// <summary>Reset the default style to its state at startup</summary>
    procedure StyleResetDefault;

    /// <summary>Get the font of a style.
    /// Returns the length of the fontName</summary>
    function StyleGetFont(AStyle: Integer): UnicodeString;

    /// <summary>Set the foreground colour of the main and additional selections and whether to use this setting.</summary>
    procedure SetSelFore(AUseSetting: Boolean; AFore: TColor);

    /// <summary>Set the background colour of the main and additional selections and whether to use this setting.</summary>
    procedure SetSelBack(AUseSetting: Boolean; ABack: TColor);

    /// <summary>When key+modifier combination km is pressed perform msg.</summary>
    procedure AssignCmdKey(AKm: Integer; AMsg: Integer);

    /// <summary>When key+modifier combination km is pressed do nothing.</summary>
    procedure ClearCmdKey(AKm: Integer);

    /// <summary>Drop all key mappings.</summary>
    procedure ClearAllCmdKeys;

    /// <summary>Set the styles for a segment of the document.</summary>
    procedure SetStylingEx(const AStyles: TDSciStyles);

    /// <summary>Start a sequence of actions that is undone and redone as a unit.
    /// May be nested.</summary>
    procedure BeginUndoAction;

    /// <summary>End a sequence of actions that is undone and redone as a unit.</summary>
    procedure EndUndoAction;

    /// <summary>Set the foreground colour of all whitespace and whether to use this setting.</summary>
    procedure SetWhitespaceFore(AUseSetting: Boolean; AFore: TColor);

    /// <summary>Set the background colour of all whitespace and whether to use this setting.</summary>
    procedure SetWhitespaceBack(AUseSetting: Boolean; ABack: TColor);

    /// <summary>Display a auto-completion list.
    /// The lenEntered parameter indicates how many characters before
    /// the caret should be used to provide context.</summary>
    procedure AutoCShow(ALenEntered: Integer; const AItemList: UnicodeString);

    /// <summary>Remove the auto-completion list from the screen.</summary>
    procedure AutoCCancel;

    /// <summary>Is there an auto-completion list visible?</summary>
    function AutoCActive: Boolean;

    /// <summary>Retrieve the position of the caret when the auto-completion list was displayed.</summary>
    function AutoCPosStart: Integer;

    /// <summary>User has selected an item so remove the list and insert the selection.</summary>
    procedure AutoCComplete;

    /// <summary>Define a set of character that when typed cancel the auto-completion list.</summary>
    procedure AutoCStops(const ACharacterSet: UnicodeString);

    /// <summary>Select the item in the auto-completion list that starts with a string.</summary>
    procedure AutoCSelect(const AText: UnicodeString);

    /// <summary>Display a list of strings and send notification when user chooses one.</summary>
    procedure UserListShow(AListType: Integer; const AItemList: UnicodeString);

    /// <summary>Register an XPM image for use in autocompletion lists.</summary>
    procedure RegisterImage(AType: Integer; const AXpmData: TBytes);

    /// <summary>Clear all the registered XPM images.</summary>
    procedure ClearRegisteredImages;

    /// <summary>Count characters between two positions.</summary>
    function CountCharacters(AStartPos: Integer; AEndPos: Integer): Integer;

    /// <summary>Set caret to a position, while removing any existing selection.</summary>
    procedure SetEmptySelection(APos: Integer);

    /// <summary>Find some text in the document.</summary>
    function FindText(AFlags: Integer; const AText: UnicodeString; var ARange: TDSciCharacterRange): Integer;

    /// <summary>On Windows, will draw the document into a display context such as a printer.</summary>
    function FormatRange(ADraw: Boolean; var AFr: TDSciRangeToFormat): Integer;

    /// <summary>Retrieve the contents of a line.
    /// Returns the length of the line.</summary>
    function GetLine(ALine: Integer): UnicodeString;

    /// <summary>Select a range of text.</summary>
    procedure SetSel(AStart: Integer; AEnd: Integer);

    /// <summary>Retrieve the selected text.
    /// Return the length of the text.</summary>
    function GetSelText: UnicodeString;

    /// <summary>Retrieve a range of text.
    /// Return the length of the text.</summary>
    function GetTextRange(AStart, AEnd: Integer): UnicodeString;

    /// <summary>Draw the selection in normal style or with selection highlighted.</summary>
    procedure HideSelection(ANormal: Boolean);

    /// <summary>Retrieve the x value of the point in the window where a position is displayed.</summary>
    function PointXFromPosition(APos: Integer): Integer;

    /// <summary>Retrieve the y value of the point in the window where a position is displayed.</summary>
    function PointYFromPosition(APos: Integer): Integer;

    /// <summary>Retrieve the line containing a position.</summary>
    function LineFromPosition(APos: Integer): Integer;

    /// <summary>Retrieve the position at the start of a line.</summary>
    function PositionFromLine(ALine: Integer): Integer;

    /// <summary>Scroll horizontally and vertically.</summary>
    procedure LineScroll(AColumns: Integer; ALines: Integer);

    /// <summary>Ensure the caret is visible.</summary>
    procedure ScrollCaret;

    /// <summary>Scroll the argument positions and the range between them into view giving
    /// priority to the primary position then the secondary position.
    /// This may be used to make a search match visible.</summary>
    procedure ScrollRange(ASecondary: Integer; APrimary: Integer);

    /// <summary>Replace the selected text with the argument text.</summary>
    procedure ReplaceSel(const AText: UnicodeString);

    /// <summary>Null operation.</summary>
    // procedure Null;

    /// <summary>Will a paste succeed?</summary>
    function CanPaste: Boolean;

    /// <summary>Are there any undoable actions in the undo history?</summary>
    function CanUndo: Boolean;

    /// <summary>Delete the undo history.</summary>
    procedure EmptyUndoBuffer;

    /// <summary>Undo one action in the undo history.</summary>
    procedure Undo;

    /// <summary>Cut the selection to the clipboard.</summary>
    procedure Cut;

    /// <summary>Copy the selection to the clipboard.</summary>
    procedure Copy;

    /// <summary>Paste the contents of the clipboard into the document replacing the selection.</summary>
    procedure Paste;

    /// <summary>Clear the selection.</summary>
    procedure Clear;

    /// <summary>Replace the contents of the document with the argument text.</summary>
    procedure SetText(const AText: UnicodeString);

    /// <summary>Retrieve all the text in the document.
    /// Returns number of characters retrieved.</summary>
    function GetText: UnicodeString;

    /// <summary>Replace the target text with the argument text.
    /// Text is counted so it can contain NULs.
    /// Returns the length of the replacement text.</summary>
    function ReplaceTarget(const AText: UnicodeString): Integer;

    /// <summary>Replace the target text with the argument text after \d processing.
    /// Text is counted so it can contain NULs.
    /// Looks for \d where d is between 1 and 9 and replaces these with the strings
    /// matched in the last search operation which were surrounded by \( and \).
    /// Returns the length of the replacement text including any change
    /// caused by processing the \d patterns.</summary>
    function ReplaceTargetRE(const AText: UnicodeString): Integer;

    /// <summary>Search for a counted string in the target and set the target to the found
    /// range. Text is counted so it can contain NULs.
    /// Returns length of range or -1 for failure in which case target is not moved.</summary>
    function SearchInTarget(const AText: UnicodeString): Integer;

    /// <summary>Show a call tip containing a definition near position pos.</summary>
    procedure CallTipShow(APos: Integer; const ADefinition: UnicodeString);

    /// <summary>Remove the call tip from the screen.</summary>
    procedure CallTipCancel;

    /// <summary>Is there an active call tip?</summary>
    function CallTipActive: Boolean;

    /// <summary>Retrieve the position where the caret was before displaying the call tip.</summary>
    function CallTipPosStart: Integer;

    /// <summary>Highlight a segment of the definition.</summary>
    procedure CallTipSetHlt(AStart: Integer; AEnd: Integer);

    /// <summary>Find the display line of a document line taking hidden lines into account.</summary>
    function VisibleFromDocLine(ALine: Integer): Integer;

    /// <summary>Find the document line of a display line taking hidden lines into account.</summary>
    function DocLineFromVisible(ALineDisplay: Integer): Integer;

    /// <summary>The number of display lines needed to wrap a document line</summary>
    function WrapCount(ALine: Integer): Integer;

    /// <summary>Make a range of lines visible.</summary>
    procedure ShowLines(ALineStart: Integer; ALineEnd: Integer);

    /// <summary>Make a range of lines invisible.</summary>
    procedure HideLines(ALineStart: Integer; ALineEnd: Integer);

    /// <summary>Switch a header line between expanded and contracted.</summary>
    procedure ToggleFold(ALine: Integer);

    /// <summary>Expand or contract a fold header.</summary>
    procedure FoldLine(ALine: Integer; AAction: Integer);

    /// <summary>Expand or contract a fold header and its children.</summary>
    procedure FoldChildren(ALine: Integer; AAction: Integer);

    /// <summary>Expand a fold header and all children. Use the level argument instead of the line's current level.</summary>
    procedure ExpandChildren(ALine: Integer; ALevel: Integer);

    /// <summary>Expand or contract all fold headers.</summary>
    procedure FoldAll(AAction: Integer);

    /// <summary>Ensure a particular line is visible by expanding any header line hiding it.</summary>
    procedure EnsureVisible(ALine: Integer);

    /// <summary>Set some style options for folding.</summary>
    procedure SetFoldFlags(AFlags: Integer);

    /// <summary>Ensure a particular line is visible by expanding any header line hiding it.
    /// Use the currently set visibility policy to determine which range to display.</summary>
    procedure EnsureVisibleEnforcePolicy(ALine: Integer);

    /// <summary>Get position of start of word.</summary>
    function WordStartPosition(APos: Integer; AOnlyWordCharacters: Boolean): Integer;

    /// <summary>Get position of end of word.</summary>
    function WordEndPosition(APos: Integer; AOnlyWordCharacters: Boolean): Integer;

    /// <summary>Measure the pixel width of some text in a particular style.
    /// NUL terminated text argument.
    /// Does not handle tab or control characters.</summary>
    function TextWidth(AStyle: Integer; const AText: UnicodeString): Integer;

    /// <summary>Retrieve the height of a particular line of text in pixels.</summary>
    function TextHeight(ALine: Integer): Integer;

    /// <summary>Append a string to the end of the document without changing the selection.</summary>
    procedure AppendText(const AText: UnicodeString);

    /// <summary>Retrieve the value of a tag from a regular expression search.</summary>
    function GetTag(ATagNumber: Integer): UnicodeString;

    /// <summary>Make the target range start and end be the same as the selection range start and end.</summary>
    procedure TargetFromSelection;

    /// <summary>Join the lines in the target.</summary>
    procedure LinesJoin;

    /// <summary>Split the lines in the target into lines that are less wide than pixelWidth
    /// where possible.</summary>
    procedure LinesSplit(APixelWidth: Integer);

    /// <summary>Set the colours used as a chequerboard pattern in the fold margin</summary>
    procedure SetFoldMarginColour(AUseSetting: Boolean; ABack: TColor);

    procedure SetFoldMarginHiColour(AUseSetting: Boolean; AFore: TColor);

    /// <summary>Move caret down one line.</summary>
    procedure LineDown;

    /// <summary>Move caret down one line extending selection to new caret position.</summary>
    procedure LineDownExtend;

    /// <summary>Move caret up one line.</summary>
    procedure LineUp;

    /// <summary>Move caret up one line extending selection to new caret position.</summary>
    procedure LineUpExtend;

    /// <summary>Move caret left one character.</summary>
    procedure CharLeft;

    /// <summary>Move caret left one character extending selection to new caret position.</summary>
    procedure CharLeftExtend;

    /// <summary>Move caret right one character.</summary>
    procedure CharRight;

    /// <summary>Move caret right one character extending selection to new caret position.</summary>
    procedure CharRightExtend;

    /// <summary>Move caret left one word.</summary>
    procedure WordLeft;

    /// <summary>Move caret left one word extending selection to new caret position.</summary>
    procedure WordLeftExtend;

    /// <summary>Move caret right one word.</summary>
    procedure WordRight;

    /// <summary>Move caret right one word extending selection to new caret position.</summary>
    procedure WordRightExtend;

    /// <summary>Move caret to first position on line.</summary>
    procedure Home;

    /// <summary>Move caret to first position on line extending selection to new caret position.</summary>
    procedure HomeExtend;

    /// <summary>Move caret to last position on line.</summary>
    procedure LineEnd;

    /// <summary>Move caret to last position on line extending selection to new caret position.</summary>
    procedure LineEndExtend;

    /// <summary>Move caret to first position in document.</summary>
    procedure DocumentStart;

    /// <summary>Move caret to first position in document extending selection to new caret position.</summary>
    procedure DocumentStartExtend;

    /// <summary>Move caret to last position in document.</summary>
    procedure DocumentEnd;

    /// <summary>Move caret to last position in document extending selection to new caret position.</summary>
    procedure DocumentEndExtend;

    /// <summary>Move caret one page up.</summary>
    procedure PageUp;

    /// <summary>Move caret one page up extending selection to new caret position.</summary>
    procedure PageUpExtend;

    /// <summary>Move caret one page down.</summary>
    procedure PageDown;

    /// <summary>Move caret one page down extending selection to new caret position.</summary>
    procedure PageDownExtend;

    /// <summary>Switch from insert to overtype mode or the reverse.</summary>
    procedure EditToggleOvertype;

    /// <summary>Cancel any modes such as call tip or auto-completion list display.</summary>
    procedure Cancel;

    /// <summary>Delete the selection or if no selection, the character before the caret.</summary>
    procedure DeleteBack;

    /// <summary>If selection is empty or all on one line replace the selection with a tab character.
    /// If more than one line selected, indent the lines.</summary>
    procedure Tab;

    /// <summary>Dedent the selected lines.</summary>
    procedure BackTab;

    /// <summary>Insert a new line, may use a CRLF, CR or LF depending on EOL mode.</summary>
    procedure NewLine;

    /// <summary>Insert a Form Feed character.</summary>
    procedure FormFeed;

    /// <summary>Move caret to before first visible character on line.
    /// If already there move to first character on line.</summary>
    procedure VCHome;

    /// <summary>Like VCHome but extending selection to new caret position.</summary>
    procedure VCHomeExtend;

    /// <summary>Magnify the displayed text by increasing the sizes by 1 point.</summary>
    procedure ZoomIn;

    /// <summary>Make the displayed text smaller by decreasing the sizes by 1 point.</summary>
    procedure ZoomOut;

    /// <summary>Delete the word to the left of the caret.</summary>
    procedure DelWordLeft;

    /// <summary>Delete the word to the right of the caret.</summary>
    procedure DelWordRight;

    /// <summary>Delete the word to the right of the caret, but not the trailing non-word characters.</summary>
    procedure DelWordRightEnd;

    /// <summary>Cut the line containing the caret.</summary>
    procedure LineCut;

    /// <summary>Delete the line containing the caret.</summary>
    procedure LineDelete;

    /// <summary>Switch the current line with the previous.</summary>
    procedure LineTranspose;

    /// <summary>Duplicate the current line.</summary>
    procedure LineDuplicate;

    /// <summary>Transform the selection to lower case.</summary>
    procedure LowerCase;

    /// <summary>Transform the selection to upper case.</summary>
    procedure UpperCase;

    /// <summary>Scroll the document down, keeping the caret visible.</summary>
    procedure LineScrollDown;

    /// <summary>Scroll the document up, keeping the caret visible.</summary>
    procedure LineScrollUp;

    /// <summary>Delete the selection or if no selection, the character before the caret.
    /// Will not delete the character before at the start of a line.</summary>
    procedure DeleteBackNotLine;

    /// <summary>Move caret to first position on display line.</summary>
    procedure HomeDisplay;

    /// <summary>Move caret to first position on display line extending selection to
    /// new caret position.</summary>
    procedure HomeDisplayExtend;

    /// <summary>Move caret to last position on display line.</summary>
    procedure LineEndDisplay;

    /// <summary>Move caret to last position on display line extending selection to new
    /// caret position.</summary>
    procedure LineEndDisplayExtend;

    procedure HomeWrap;

    procedure HomeWrapExtend;

    procedure LineEndWrap;

    procedure LineEndWrapExtend;

    procedure VCHomeWrap;

    procedure VCHomeWrapExtend;

    /// <summary>Copy the line containing the caret.</summary>
    procedure LineCopy;

    /// <summary>Move the caret inside current view if it's not there already.</summary>
    procedure MoveCaretInsideView;

    /// <summary>How many characters are on a line, including end of line characters?</summary>
    function LineLength(ALine: Integer): Integer;

    /// <summary>Highlight the characters at two positions.</summary>
    procedure BraceHighlight(APos1: Integer; APos2: Integer);

    /// <summary>Use specified indicator to highlight matching braces instead of changing their style.</summary>
    procedure BraceHighlightIndicator(AUseBraceHighlightIndicator: Boolean; AIndicator: Integer);

    /// <summary>Highlight the character at a position indicating there is no matching brace.</summary>
    procedure BraceBadLight(APos: Integer);

    /// <summary>Use specified indicator to highlight non matching brace instead of changing its style.</summary>
    procedure BraceBadLightIndicator(AUseBraceBadLightIndicator: Boolean; AIndicator: Integer);

    /// <summary>Find the position of a matching brace or INVALID_POSITION if no match.</summary>
    function BraceMatch(APos: Integer): Integer;

    /// <summary>Sets the current caret position to be the search anchor.</summary>
    procedure SearchAnchor;

    /// <summary>Find some text starting at the search anchor.
    /// Does not ensure the selection is visible.</summary>
    function SearchNext(AFlags: Integer; const AText: UnicodeString): Integer;

    /// <summary>Find some text starting at the search anchor and moving backwards.
    /// Does not ensure the selection is visible.</summary>
    function SearchPrev(AFlags: Integer; const AText: UnicodeString): Integer;

    /// <summary>Retrieves the number of lines completely visible.</summary>
    function LinesOnScreen: Integer;

    /// <summary>Set whether a pop up menu is displayed automatically when the user presses
    /// the wrong mouse button.</summary>
    procedure UsePopUp(AAllowPopUp: Boolean);

    /// <summary>Is the selection rectangular? The alternative is the more common stream selection.</summary>
    function SelectionIsRectangle: Boolean;

    /// <summary>Create a new document object.
    /// Starts with reference count of 1 and not selected into editor.</summary>
    function CreateDocument: TDSciDocument;

    /// <summary>Extend life of document.</summary>
    procedure AddRefDocument(ADoc: TDSciDocument);

    /// <summary>Release a reference to the document, deleting document if it fades to black.</summary>
    procedure ReleaseDocument(ADoc: TDSciDocument);

    /// <summary>Move to the previous change in capitalisation.</summary>
    procedure WordPartLeft;

    /// <summary>Move to the previous change in capitalisation extending selection
    /// to new caret position.</summary>
    procedure WordPartLeftExtend;

    /// <summary>Move to the change next in capitalisation.</summary>
    procedure WordPartRight;

    /// <summary>Move to the next change in capitalisation extending selection
    /// to new caret position.</summary>
    procedure WordPartRightExtend;

    /// <summary>Set the way the display area is determined when a particular line
    /// is to be moved to by Find, FindNext, GotoLine, etc.</summary>
    procedure SetVisiblePolicy(AVisiblePolicy: Integer; AVisibleSlop: Integer);

    /// <summary>Delete back from the current position to the start of the line.</summary>
    procedure DelLineLeft;

    /// <summary>Delete forwards from the current position to the end of the line.</summary>
    procedure DelLineRight;

    /// <summary>Set the last x chosen value to be the caret x position.</summary>
    procedure ChooseCaretX;

    /// <summary>Set the focus to this Scintilla widget.</summary>
    procedure GrabFocus;

    /// <summary>Set the way the caret is kept visible when going sideways.
    /// The exclusion zone is given in pixels.</summary>
    procedure SetXCaretPolicy(ACaretPolicy: Integer; ACaretSlop: Integer);

    /// <summary>Set the way the line the caret is on is kept visible.
    /// The exclusion zone is given in lines.</summary>
    procedure SetYCaretPolicy(ACaretPolicy: Integer; ACaretSlop: Integer);

    /// <summary>Move caret between paragraphs (delimited by empty lines).</summary>
    procedure ParaDown;

    procedure ParaDownExtend;

    procedure ParaUp;

    procedure ParaUpExtend;

    /// <summary>Given a valid document position, return the previous position taking code
    /// page into account. Returns 0 if passed 0.</summary>
    function PositionBefore(APos: Integer): Integer;

    /// <summary>Given a valid document position, return the next position taking code
    /// page into account. Maximum value returned is the last position in the document.</summary>
    function PositionAfter(APos: Integer): Integer;

    /// <summary>Given a valid document position, return a position that differs in a number
    /// of characters. Returned value is always between 0 and last position in document.</summary>
    function PositionRelative(APos: Integer; ARelative: Integer): Integer;

    /// <summary>Copy a range of text to the clipboard. Positions are clipped into the document.</summary>
    procedure CopyRange(AStart: Integer; AEnd: Integer);

    /// <summary>Copy argument text to the clipboard.</summary>
    procedure CopyText(const AText: UnicodeString);

    /// <summary>Retrieve the position of the start of the selection at the given line (INVALID_POSITION if no selection on this line).</summary>
    function GetLineSelStartPosition(ALine: Integer): Integer;

    /// <summary>Retrieve the position of the end of the selection at the given line (INVALID_POSITION if no selection on this line).</summary>
    function GetLineSelEndPosition(ALine: Integer): Integer;

    /// <summary>Move caret down one line, extending rectangular selection to new caret position.</summary>
    procedure LineDownRectExtend;

    /// <summary>Move caret up one line, extending rectangular selection to new caret position.</summary>
    procedure LineUpRectExtend;

    /// <summary>Move caret left one character, extending rectangular selection to new caret position.</summary>
    procedure CharLeftRectExtend;

    /// <summary>Move caret right one character, extending rectangular selection to new caret position.</summary>
    procedure CharRightRectExtend;

    /// <summary>Move caret to first position on line, extending rectangular selection to new caret position.</summary>
    procedure HomeRectExtend;

    /// <summary>Move caret to before first visible character on line.
    /// If already there move to first character on line.
    /// In either case, extend rectangular selection to new caret position.</summary>
    procedure VCHomeRectExtend;

    /// <summary>Move caret to last position on line, extending rectangular selection to new caret position.</summary>
    procedure LineEndRectExtend;

    /// <summary>Move caret one page up, extending rectangular selection to new caret position.</summary>
    procedure PageUpRectExtend;

    /// <summary>Move caret one page down, extending rectangular selection to new caret position.</summary>
    procedure PageDownRectExtend;

    /// <summary>Move caret to top of page, or one page up if already at top of page.</summary>
    procedure StutteredPageUp;

    /// <summary>Move caret to top of page, or one page up if already at top of page, extending selection to new caret position.</summary>
    procedure StutteredPageUpExtend;

    /// <summary>Move caret to bottom of page, or one page down if already at bottom of page.</summary>
    procedure StutteredPageDown;

    /// <summary>Move caret to bottom of page, or one page down if already at bottom of page, extending selection to new caret position.</summary>
    procedure StutteredPageDownExtend;

    /// <summary>Move caret left one word, position cursor at end of word.</summary>
    procedure WordLeftEnd;

    /// <summary>Move caret left one word, position cursor at end of word, extending selection to new caret position.</summary>
    procedure WordLeftEndExtend;

    /// <summary>Move caret right one word, position cursor at end of word.</summary>
    procedure WordRightEnd;

    /// <summary>Move caret right one word, position cursor at end of word, extending selection to new caret position.</summary>
    procedure WordRightEndExtend;

    /// <summary>Reset the set of characters for whitespace and word characters to the defaults.</summary>
    procedure SetCharsDefault;

    /// <summary>Get currently selected item position in the auto-completion list</summary>
    function AutoCGetCurrent: Integer;

    /// <summary>Get currently selected item text in the auto-completion list
    /// Returns the length of the item text</summary>
    function AutoCGetCurrentText: UnicodeString;

    /// <summary>Enlarge the document to a particular size of text bytes.</summary>
    procedure Allocate(ABytes: Integer);

    /// <summary>Returns the target converted to UTF8.
    /// Return the length in bytes.</summary>
    // function TargetAsUTF8(AS: PAnsiChar): Integer;

    /// <summary>Set the length of the utf8 argument for calling EncodedFromUTF8.
    /// Set to -1 and the string will be measured to the first nul.</summary>
    // procedure SetLengthForEncode(ABytes: Integer);

    /// <summary>Translates a UTF8 string into the document encoding.
    /// Return the length of the result in bytes.
    /// On error return 0.</summary>
    // function EncodedFromUTF8(AUtf8: PAnsiChar; AEncoded: PAnsiChar): Integer;

    /// <summary>Find the position of a column on a line taking into account tabs and
    /// multi-byte characters. If beyond end of line, return line end position.</summary>
    function FindColumn(ALine: Integer; AColumn: Integer): Integer;

    /// <summary>Switch between sticky and non-sticky: meant to be bound to a key.</summary>
    procedure ToggleCaretSticky;

    /// <summary>Duplicate the selection. If selection empty duplicate the line containing the caret.</summary>
    procedure SelectionDuplicate;

    /// <summary>Turn a indicator on over a range.</summary>
    procedure IndicatorFillRange(APosition: Integer; AFillLength: Integer);

    /// <summary>Turn a indicator off over a range.</summary>
    procedure IndicatorClearRange(APosition: Integer; AClearLength: Integer);

    /// <summary>Are any indicators present at position?</summary>
    function IndicatorAllOnFor(APosition: Integer): Integer;

    /// <summary>What value does a particular indicator have at at a position?</summary>
    function IndicatorValueAt(AIndicator: Integer; APosition: Integer): Integer;

    /// <summary>Where does a particular indicator start?</summary>
    function IndicatorStart(AIndicator: Integer; APosition: Integer): Integer;

    /// <summary>Where does a particular indicator end?</summary>
    function IndicatorEnd(AIndicator: Integer; APosition: Integer): Integer;

    /// <summary>Copy the selection, if selection empty copy the line with the caret</summary>
    procedure CopyAllowLine;

    /// <summary>Return a position which, to avoid performance costs, should not be within
    /// the range of a call to GetRangePointer.</summary>
    function GetGapPosition: Integer;

    /// <summary>Which symbol was defined for markerNumber with MarkerDefine</summary>
    function MarkerSymbolDefined(AMarkerNumber: Integer): Integer;

    /// <summary>Clear the margin text on all lines</summary>
    procedure MarginTextClearAll;

    /// <summary>Clear the annotations from all lines</summary>
    procedure AnnotationClearAll;

    /// <summary>Release all extended (&gt;255) style numbers</summary>
    procedure ReleaseAllExtendedStyles;

    /// <summary>Allocate some extended (&gt;255) style numbers and return the start of the range</summary>
    function AllocateExtendedStyles(ANumberStyles: Integer): Integer;

    /// <summary>Add a container action to the undo stack</summary>
    procedure AddUndoAction(AToken: Integer; AFlags: Integer);

    /// <summary>Find the position of a character from a point within the window.</summary>
    function CharPositionFromPoint(AX: Integer; AY: Integer): Integer;

    /// <summary>Find the position of a character from a point within the window.
    /// Return INVALID_POSITION if not close to text.</summary>
    function CharPositionFromPointClose(AX: Integer; AY: Integer): Integer;

    /// <summary>Clear selections to a single empty stream selection</summary>
    procedure ClearSelections;

    /// <summary>Set a simple selection</summary>
    function SetSelection(ACaret: Integer; AAnchor: Integer): Integer;

    /// <summary>Add a selection</summary>
    function AddSelection(ACaret: Integer; AAnchor: Integer): Integer;

    /// <summary>Drop one selection</summary>
    procedure DropSelectionN(ASelection: Integer);

    /// <summary>Set the main selection to the next selection.</summary>
    procedure RotateSelection;

    /// <summary>Swap that caret and anchor of the main selection.</summary>
    procedure SwapMainAnchorCaret;

    /// <summary>Indicate that the internal state of a lexer has changed over a range and therefore
    /// there may be a need to redraw.</summary>
    function ChangeLexerState(AStart: Integer; AEnd: Integer): Integer;

    /// <summary>Find the next line at or after lineStart that is a contracted fold header line.
    /// Return -1 when no more lines.</summary>
    function ContractedFoldNext(ALineStart: Integer): Integer;

    /// <summary>Centre current line in window.</summary>
    procedure VerticalCentreCaret;

    /// <summary>Move the selected lines up one line, shifting the line above after the selection</summary>
    procedure MoveSelectedLinesUp;

    /// <summary>Move the selected lines down one line, shifting the line below before the selection</summary>
    procedure MoveSelectedLinesDown;

    /// <summary>Set the scale factor in percent for future RGBA image data.</summary>
    procedure RGBAImageSetScale(AScalePercent: Integer);

    /// <summary>Define a marker from RGBA data.
    /// It has the width and height from RGBAImageSetWidth/Height</summary>
    procedure MarkerDefineRGBAImage(AMarkerNumber: Integer; APixels: PAnsiChar);

    /// <summary>Register an RGBA image for use in autocompletion lists.
    /// It has the width and height from RGBAImageSetWidth/Height</summary>
    procedure RegisterRGBAImage(AType: Integer; APixels: PAnsiChar);

    /// <summary>Scroll to start of document.</summary>
    procedure ScrollToStart;

    /// <summary>Scroll to end of document.</summary>
    procedure ScrollToEnd;

    /// <summary>Create an ILoader*.</summary>
    function CreateLoader(ABytes: Integer): Pointer;

    /// <summary>On OS X, show a find indicator.</summary>
    // procedure FindIndicatorShow(AStart: Integer; AEnd: Integer);

    /// <summary>On OS X, flash a find indicator, then fade out.</summary>
    // procedure FindIndicatorFlash(AStart: Integer; AEnd: Integer);

    /// <summary>On OS X, hide the find indicator.</summary>
    // procedure FindIndicatorHide;

    /// <summary>Move caret to before first visible character on display line.
    /// If already there move to first character on display line.</summary>
    procedure VCHomeDisplay;

    /// <summary>Like VCHomeDisplay but extending selection to new caret position.</summary>
    procedure VCHomeDisplayExtend;

    /// <summary>Remove a character representation.</summary>
    procedure ClearRepresentation(AEncodedCharacter: AnsiString);

    /// <summary>Start notifying the container of all key presses and commands.</summary>
    procedure StartRecord;

    /// <summary>Stop notifying the container of all key presses and commands.</summary>
    procedure StopRecord;

    /// <summary>Colourise a segment of the document using the current lexing language.</summary>
    procedure Colourise(AStart: Integer; AEnd: Integer);

    /// <summary>Set up the key words used by the lexer.</summary>
    procedure SetKeyWords(AKeywordSet: Integer; const AKeyWords: UnicodeString);

    /// <summary>Set the lexing language of the document based on string name.</summary>
    procedure SetLexerLanguage(const ALanguage: UnicodeString);

    /// <summary>Load a lexer library (dll / so).</summary>
    procedure LoadLexerLibrary(const APath: UnicodeString);

    /// <summary>Retrieve a "property" value previously set with SetProperty.</summary>
    function GetProperty(const AKey: UnicodeString): UnicodeString;

    /// <summary>Retrieve a "property" value previously set with SetProperty,
    /// with "$()" variable replacement on returned buffer.</summary>
    function GetPropertyExpanded(const AKey: UnicodeString): UnicodeString;

    /// <summary>For private communication between an application and a known lexer.</summary>
    function PrivateLexerCall(AOperation: Integer; APointer: Integer): Integer;

    /// <summary>Retrieve a '\n' separated list of properties understood by the current lexer.</summary>
    function PropertyNames: UnicodeString;

    /// <summary>Retrieve the type of a property.</summary>
    function PropertyType(AName: UnicodeString): Integer;

    /// <summary>Describe a property.</summary>
    function DescribeProperty(AName: UnicodeString): UnicodeString;

    /// <summary>Retrieve a '\n' separated list of descriptions of the keyword sets understood by the current lexer.</summary>
    function DescribeKeyWordSets: UnicodeString;

    /// <summary>Allocate a set of sub styles for a particular base style, returning start of range</summary>
    function AllocateSubStyles(AStyleBase: Integer; ANumberStyles: Integer): Integer;

    /// <summary>Free allocated sub styles</summary>
    procedure FreeSubStyles;
{$ENDREGION Scintilla methods}
  public

    // -------------------------------------------------------------------------
    // Scintilla properties ----------------------------------------------------
    // -------------------------------------------------------------------------
{$REGION 'Scintilla properties'}
    /// <summary>Returns the number of bytes in the document.</summary>
    function GetLength: Integer;

    /// <summary>Returns the character byte at the position.</summary>
    function GetCharAt(APos: Integer): Integer;

    /// <summary>Returns the position of the caret.</summary>
    function GetCurrentPos: Integer;

    /// <summary>Returns the position of the opposite end of the selection to the caret.</summary>
    function GetAnchor: Integer;

    /// <summary>Returns the style byte at the position.</summary>
    function GetStyleAt(APos: Integer): Integer;

    /// <summary>Choose between collecting actions into the undo
    /// history and discarding them.</summary>
    procedure SetUndoCollection(ACollectUndo: Boolean);

    /// <summary>Is undo history being collected?</summary>
    function GetUndoCollection: Boolean;

    /// <summary>Are white space characters currently visible?
    /// Returns one of SCWS_* constants.</summary>
    function GetViewWS: Integer;

    /// <summary>Make white space characters invisible, always visible or visible outside indentation.</summary>
    procedure SetViewWS(AViewWS: Integer);

    /// <summary>Set the selection anchor to a position. The anchor is the opposite
    /// end of the selection from the caret.</summary>
    procedure SetAnchor(APosAnchor: Integer);

    /// <summary>Retrieve the position of the last correctly styled character.</summary>
    function GetEndStyled: Integer;

    /// <summary>Retrieve the current end of line mode - one of CRLF, CR, or LF.</summary>
    function GetEOLMode: Integer;

    /// <summary>Set the current end of line mode.</summary>
    procedure SetEOLMode(AEolMode: Integer);

    /// <summary>Is drawing done first into a buffer or direct to the screen?</summary>
    function GetBufferedDraw: Boolean;

    /// <summary>If drawing is buffered then each line of text is drawn into a bitmap buffer
    /// before drawing it to the screen to avoid flicker.</summary>
    procedure SetBufferedDraw(ABuffered: Boolean);

    /// <summary>Change the visible size of a tab to be a multiple of the width of a space character.</summary>
    procedure SetTabWidth(ATabWidth: Integer);

    /// <summary>Retrieve the visible size of a tab.</summary>
    function GetTabWidth: Integer;

    /// <summary>Set the code page used to interpret the bytes of the document as characters.
    /// The SC_CP_UTF8 value can be used to enter Unicode mode.</summary>
    procedure SetCodePage(ACodePage: Integer);

    /// <summary>Set a margin to be either numeric or symbolic.</summary>
    procedure SetMarginTypeN(AMargin: Integer; AMarginType: Integer);

    /// <summary>Retrieve the type of a margin.</summary>
    function GetMarginTypeN(AMargin: Integer): Integer;

    /// <summary>Set the width of a margin to a width expressed in pixels.</summary>
    procedure SetMarginWidthN(AMargin: Integer; APixelWidth: Integer);

    /// <summary>Retrieve the width of a margin in pixels.</summary>
    function GetMarginWidthN(AMargin: Integer): Integer;

    /// <summary>Set a mask that determines which markers are displayed in a margin.</summary>
    procedure SetMarginMaskN(AMargin: Integer; AMask: Integer);

    /// <summary>Retrieve the marker mask of a margin.</summary>
    function GetMarginMaskN(AMargin: Integer): Integer;

    /// <summary>Make a margin sensitive or insensitive to mouse clicks.</summary>
    procedure SetMarginSensitiveN(AMargin: Integer; ASensitive: Boolean);

    /// <summary>Retrieve the mouse click sensitivity of a margin.</summary>
    function GetMarginSensitiveN(AMargin: Integer): Boolean;

    /// <summary>Set the cursor shown when the mouse is inside a margin.</summary>
    procedure SetMarginCursorN(AMargin: Integer; ACursor: Integer);

    /// <summary>Retrieve the cursor shown in a margin.</summary>
    function GetMarginCursorN(AMargin: Integer): Integer;

    /// <summary>Set the foreground colour of a style.</summary>
    procedure StyleSetFore(AStyle: Integer; AFore: TColor);

    /// <summary>Set the background colour of a style.</summary>
    procedure StyleSetBack(AStyle: Integer; ABack: TColor);

    /// <summary>Set a style to be bold or not.</summary>
    procedure StyleSetBold(AStyle: Integer; ABold: Boolean);

    /// <summary>Set a style to be italic or not.</summary>
    procedure StyleSetItalic(AStyle: Integer; AItalic: Boolean);

    /// <summary>Set the size of characters of a style.</summary>
    procedure StyleSetSize(AStyle: Integer; ASizePoints: Integer);

    /// <summary>Set the font of a style.</summary>
    procedure StyleSetFont(AStyle: Integer; const AFontName: UnicodeString);

    /// <summary>Set a style to have its end of line filled or not.</summary>
    procedure StyleSetEOLFilled(AStyle: Integer; AFilled: Boolean);

    /// <summary>Set a style to be underlined or not.</summary>
    procedure StyleSetUnderline(AStyle: Integer; AUnderline: Boolean);

    /// <summary>Get the foreground colour of a style.</summary>
    function StyleGetFore(AStyle: Integer): TColor;

    /// <summary>Get the background colour of a style.</summary>
    function StyleGetBack(AStyle: Integer): TColor;

    /// <summary>Get is a style bold or not.</summary>
    function StyleGetBold(AStyle: Integer): Boolean;

    /// <summary>Get is a style italic or not.</summary>
    function StyleGetItalic(AStyle: Integer): Boolean;

    /// <summary>Get the size of characters of a style.</summary>
    function StyleGetSize(AStyle: Integer): Integer;

    /// <summary>Get is a style to have its end of line filled or not.</summary>
    function StyleGetEOLFilled(AStyle: Integer): Boolean;

    /// <summary>Get is a style underlined or not.</summary>
    function StyleGetUnderline(AStyle: Integer): Boolean;

    /// <summary>Get is a style mixed case, or to force upper or lower case.</summary>
    function StyleGetCase(AStyle: Integer): Integer;

    /// <summary>Get the character get of the font in a style.</summary>
    function StyleGetCharacterSet(AStyle: Integer): Integer;

    /// <summary>Get is a style visible or not.</summary>
    function StyleGetVisible(AStyle: Integer): Boolean;

    /// <summary>Get is a style changeable or not (read only).
    /// Experimental feature, currently buggy.</summary>
    function StyleGetChangeable(AStyle: Integer): Boolean;

    /// <summary>Get is a style a hotspot or not.</summary>
    function StyleGetHotSpot(AStyle: Integer): Boolean;

    /// <summary>Set a style to be mixed case, or to force upper or lower case.</summary>
    procedure StyleSetCase(AStyle: Integer; ACaseForce: Integer);

    /// <summary>Set the size of characters of a style. Size is in points multiplied by 100.</summary>
    procedure StyleSetSizeFractional(AStyle: Integer; ACaseForce: Integer);

    /// <summary>Get the size of characters of a style in points multiplied by 100</summary>
    function StyleGetSizeFractional(AStyle: Integer): Integer;

    /// <summary>Set the weight of characters of a style.</summary>
    procedure StyleSetWeight(AStyle: Integer; AWeight: Integer);

    /// <summary>Get the weight of characters of a style.</summary>
    function StyleGetWeight(AStyle: Integer): Integer;

    /// <summary>Set the character set of the font in a style.</summary>
    procedure StyleSetCharacterSet(AStyle: Integer; ACharacterSet: Integer);

    /// <summary>Set a style to be a hotspot or not.</summary>
    procedure StyleSetHotSpot(AStyle: Integer; AHotspot: Boolean);

    /// <summary>Get the alpha of the selection.</summary>
    function GetSelAlpha: Integer;

    /// <summary>Set the alpha of the selection.</summary>
    procedure SetSelAlpha(AAlpha: Integer);

    /// <summary>Is the selection end of line filled?</summary>
    function GetSelEOLFilled: Boolean;

    /// <summary>Set the selection to have its end of line filled or not.</summary>
    procedure SetSelEOLFilled(AFilled: Boolean);

    /// <summary>Set the foreground colour of the caret.</summary>
    procedure SetCaretFore(AFore: TColor);

    /// <summary>Set a style to be visible or not.</summary>
    procedure StyleSetVisible(AStyle: Integer; AVisible: Boolean);

    /// <summary>Get the time in milliseconds that the caret is on and off.</summary>
    function GetCaretPeriod: Integer;

    /// <summary>Get the time in milliseconds that the caret is on and off. 0 = steady on.</summary>
    procedure SetCaretPeriod(APeriodMilliseconds: Integer);

    /// <summary>Set the set of characters making up words for when moving or selecting by word.
    /// First sets defaults like SetCharsDefault.</summary>
    procedure SetWordChars(const ACharacters: AnsiString);

    /// <summary>Get the set of characters making up words for when moving or selecting by word.
    /// Retuns the number of characters</summary>
    function GetWordChars: AnsiString;

    /// <summary>Set an indicator to plain, squiggle or TT.</summary>
    procedure IndicSetStyle(AIndic: Integer; AStyle: Integer);

    /// <summary>Retrieve the style of an indicator.</summary>
    function IndicGetStyle(AIndic: Integer): Integer;

    /// <summary>Set the foreground colour of an indicator.</summary>
    procedure IndicSetFore(AIndic: Integer; AFore: TColor);

    /// <summary>Retrieve the foreground colour of an indicator.</summary>
    function IndicGetFore(AIndic: Integer): TColor;

    /// <summary>Set an indicator to draw under text or over(default).</summary>
    procedure IndicSetUnder(AIndic: Integer; AUnder: Boolean);

    /// <summary>Retrieve whether indicator drawn under or over text.</summary>
    function IndicGetUnder(AIndic: Integer): Boolean;

    /// <summary>Set the size of the dots used to mark space characters.</summary>
    procedure SetWhitespaceSize(ASize: Integer);

    /// <summary>Get the size of the dots used to mark space characters.</summary>
    function GetWhitespaceSize: Integer;

    /// <summary>Divide each styling byte into lexical class bits (default: 5) and indicator
    /// bits (default: 3). If a lexer requires more than 32 lexical states, then this
    /// is used to expand the possible states.</summary>
    procedure SetStyleBits(ABits: Integer);

    /// <summary>Retrieve number of bits in style bytes used to hold the lexical state.</summary>
    function GetStyleBits: Integer;

    /// <summary>Used to hold extra styling information for each line.</summary>
    procedure SetLineState(ALine: Integer; AState: Integer);

    /// <summary>Retrieve the extra styling information for a line.</summary>
    function GetLineState(ALine: Integer): Integer;

    /// <summary>Retrieve the last line number that has line state.</summary>
    function GetMaxLineState: Integer;

    /// <summary>Is the background of the line containing the caret in a different colour?</summary>
    function GetCaretLineVisible: Boolean;

    /// <summary>Display the background of the line containing the caret in a different colour.</summary>
    procedure SetCaretLineVisible(AShow: Boolean);

    /// <summary>Get the colour of the background of the line containing the caret.</summary>
    function GetCaretLineBack: TColor;

    /// <summary>Set the colour of the background of the line containing the caret.</summary>
    procedure SetCaretLineBack(ABack: TColor);

    /// <summary>Set a style to be changeable or not (read only).
    /// Experimental feature, currently buggy.</summary>
    procedure StyleSetChangeable(AStyle: Integer; AChangeable: Boolean);

    /// <summary>Change the separator character in the string setting up an auto-completion list.
    /// Default is space but can be changed if items contain space.</summary>
    procedure AutoCSetSeparator(ASeparatorCharacter: AnsiChar);

    /// <summary>Retrieve the auto-completion list separator character.</summary>
    function AutoCGetSeparator: AnsiChar;

    /// <summary>Should the auto-completion list be cancelled if the user backspaces to a
    /// position before where the box was created.</summary>
    procedure AutoCSetCancelAtStart(ACancel: Boolean);

    /// <summary>Retrieve whether auto-completion cancelled by backspacing before start.</summary>
    function AutoCGetCancelAtStart: Boolean;

    /// <summary>Define a set of characters that when typed will cause the autocompletion to
    /// choose the selected item.</summary>
    procedure AutoCSetFillUps(const ACharacterSet: UnicodeString);

    /// <summary>Should a single item auto-completion list automatically choose the item.</summary>
    procedure AutoCSetChooseSingle(AChooseSingle: Boolean);

    /// <summary>Retrieve whether a single item auto-completion list automatically choose the item.</summary>
    function AutoCGetChooseSingle: Boolean;

    /// <summary>Set whether case is significant when performing auto-completion searches.</summary>
    procedure AutoCSetIgnoreCase(AIgnoreCase: Boolean);

    /// <summary>Retrieve state of ignore case flag.</summary>
    function AutoCGetIgnoreCase: Boolean;

    /// <summary>Set whether or not autocompletion is hidden automatically when nothing matches.</summary>
    procedure AutoCSetAutoHide(AAutoHide: Boolean);

    /// <summary>Retrieve whether or not autocompletion is hidden automatically when nothing matches.</summary>
    function AutoCGetAutoHide: Boolean;

    /// <summary>Set whether or not autocompletion deletes any word characters
    /// after the inserted text upon completion.</summary>
    procedure AutoCSetDropRestOfWord(ADropRestOfWord: Boolean);

    /// <summary>Retrieve whether or not autocompletion deletes any word characters
    /// after the inserted text upon completion.</summary>
    function AutoCGetDropRestOfWord: Boolean;

    /// <summary>Retrieve the auto-completion list type-separator character.</summary>
    function AutoCGetTypeSeparator: AnsiChar;

    /// <summary>Change the type-separator character in the string setting up an auto-completion list.
    /// Default is '?' but can be changed if items contain '?'.</summary>
    procedure AutoCSetTypeSeparator(ASeparatorCharacter: AnsiChar);

    /// <summary>Set the maximum width, in characters, of auto-completion and user lists.
    /// Set to 0 to autosize to fit longest item, which is the default.</summary>
    procedure AutoCSetMaxWidth(ACharacterCount: Integer);

    /// <summary>Get the maximum width, in characters, of auto-completion and user lists.</summary>
    function AutoCGetMaxWidth: Integer;

    /// <summary>Set the maximum height, in rows, of auto-completion and user lists.
    /// The default is 5 rows.</summary>
    procedure AutoCSetMaxHeight(ARowCount: Integer);

    /// <summary>Set the maximum height, in rows, of auto-completion and user lists.</summary>
    function AutoCGetMaxHeight: Integer;

    /// <summary>Set the number of spaces used for one level of indentation.</summary>
    procedure SetIndent(AIndentSize: Integer);

    /// <summary>Retrieve indentation size.</summary>
    function GetIndent: Integer;

    /// <summary>Indentation will only use space characters if useTabs is false, otherwise
    /// it will use a combination of tabs and spaces.</summary>
    procedure SetUseTabs(AUseTabs: Boolean);

    /// <summary>Retrieve whether tabs will be used in indentation.</summary>
    function GetUseTabs: Boolean;

    /// <summary>Change the indentation of a line to a number of columns.</summary>
    procedure SetLineIndentation(ALine: Integer; AIndentSize: Integer);

    /// <summary>Retrieve the number of columns that a line is indented.</summary>
    function GetLineIndentation(ALine: Integer): Integer;

    /// <summary>Retrieve the position before the first non indentation character on a line.</summary>
    function GetLineIndentPosition(ALine: Integer): Integer;

    /// <summary>Retrieve the column number of a position, taking tab width into account.</summary>
    function GetColumn(APos: Integer): Integer;

    /// <summary>Show or hide the horizontal scroll bar.</summary>
    procedure SetHScrollBar(AShow: Boolean);

    /// <summary>Is the horizontal scroll bar visible?</summary>
    function GetHScrollBar: Boolean;

    /// <summary>Show or hide indentation guides.</summary>
    procedure SetIndentationGuides(AIndentView: Integer);

    /// <summary>Are the indentation guides visible?</summary>
    function GetIndentationGuides: Integer;

    /// <summary>Set the highlighted indentation guide column.
    /// 0 = no highlighted guide.</summary>
    procedure SetHighlightGuide(AColumn: Integer);

    /// <summary>Get the highlighted indentation guide column.</summary>
    function GetHighlightGuide: Integer;

    /// <summary>Get the position after the last visible characters on a line.</summary>
    function GetLineEndPosition(ALine: Integer): Integer;

    /// <summary>Get the code page used to interpret the bytes of the document as characters.</summary>
    function GetCodePage: Integer;

    /// <summary>Get the foreground colour of the caret.</summary>
    function GetCaretFore: TColor;

    /// <summary>In read-only mode?</summary>
    function GetReadOnly: Boolean;

    /// <summary>Sets the position of the caret.</summary>
    procedure SetCurrentPos(APos: Integer);

    /// <summary>Sets the position that starts the selection - this becomes the anchor.</summary>
    procedure SetSelectionStart(APos: Integer);

    /// <summary>Returns the position at the start of the selection.</summary>
    function GetSelectionStart: Integer;

    /// <summary>Sets the position that ends the selection - this becomes the currentPosition.</summary>
    procedure SetSelectionEnd(APos: Integer);

    /// <summary>Returns the position at the end of the selection.</summary>
    function GetSelectionEnd: Integer;

    /// <summary>Sets the print magnification added to the point size of each style for printing.</summary>
    procedure SetPrintMagnification(AMagnification: Integer);

    /// <summary>Returns the print magnification.</summary>
    function GetPrintMagnification: Integer;

    /// <summary>Modify colours when printing for clearer printed text.</summary>
    procedure SetPrintColourMode(AMode: Integer);

    /// <summary>Returns the print colour mode.</summary>
    function GetPrintColourMode: Integer;

    /// <summary>Retrieve the display line at the top of the display.</summary>
    function GetFirstVisibleLine: Integer;

    /// <summary>Returns the number of lines in the document. There is always at least one.</summary>
    function GetLineCount: Integer;

    /// <summary>Sets the size in pixels of the left margin.</summary>
    procedure SetMarginLeft(APixelWidth: Integer);

    /// <summary>Returns the size in pixels of the left margin.</summary>
    function GetMarginLeft: Integer;

    /// <summary>Sets the size in pixels of the right margin.</summary>
    procedure SetMarginRight(APixelWidth: Integer);

    /// <summary>Returns the size in pixels of the right margin.</summary>
    function GetMarginRight: Integer;

    /// <summary>Is the document different from when it was last saved?</summary>
    function GetModify: Boolean;

    /// <summary>Set to read only or read write.</summary>
    procedure SetReadOnly(AReadOnly: Boolean);

    /// <summary>Retrieve the number of characters in the document.</summary>
    function GetTextLength: Integer;

    /// <summary>Retrieve a pointer to a function that processes messages for this Scintilla.</summary>
    function GetDirectFunction: TDScintillaFunction;

    /// <summary>Retrieve a pointer value to use as the first argument when calling
    /// the function returned by GetDirectFunction.</summary>
    function GetDirectPointer: Pointer;

    /// <summary>Set to overtype (true) or insert mode.</summary>
    procedure SetOvertype(AOvertype: Boolean);

    /// <summary>Returns true if overtype mode is active otherwise false is returned.</summary>
    function GetOvertype: Boolean;

    /// <summary>Set the width of the insert mode caret.</summary>
    procedure SetCaretWidth(APixelWidth: Integer);

    /// <summary>Returns the width of the insert mode caret.</summary>
    function GetCaretWidth: Integer;

    /// <summary>Sets the position that starts the target which is used for updating the
    /// document without affecting the scroll position.</summary>
    procedure SetTargetStart(APos: Integer);

    /// <summary>Get the position that starts the target.</summary>
    function GetTargetStart: Integer;

    /// <summary>Sets the position that ends the target which is used for updating the
    /// document without affecting the scroll position.</summary>
    procedure SetTargetEnd(APos: Integer);

    /// <summary>Get the position that ends the target.</summary>
    function GetTargetEnd: Integer;

    /// <summary>Set the search flags used by SearchInTarget.</summary>
    procedure SetSearchFlags(AFlags: Integer);

    /// <summary>Get the search flags used by SearchInTarget.</summary>
    function GetSearchFlags: Integer;

    /// <summary>Set the start position in order to change when backspacing removes the calltip.</summary>
    procedure CallTipSetPosStart(APosStart: Integer);

    /// <summary>Set the background colour for the call tip.</summary>
    procedure CallTipSetBack(ABack: TColor);

    /// <summary>Set the foreground colour for the call tip.</summary>
    procedure CallTipSetFore(AFore: TColor);

    /// <summary>Set the foreground colour for the highlighted part of the call tip.</summary>
    procedure CallTipSetForeHlt(AFore: TColor);

    /// <summary>Enable use of STYLE_CALLTIP and set call tip tab size in pixels.</summary>
    procedure CallTipUseStyle(ATabSize: Integer);

    /// <summary>Set position of calltip, above or below text.</summary>
    procedure CallTipSetPosition(AAbove: Boolean);

    /// <summary>Set the fold level of a line.
    /// This encodes an integer level along with flags indicating whether the
    /// line is a header and whether it is effectively white space.</summary>
    procedure SetFoldLevel(ALine: Integer; ALevel: Integer);

    /// <summary>Retrieve the fold level of a line.</summary>
    function GetFoldLevel(ALine: Integer): Integer;

    /// <summary>Find the last child line of a header line.</summary>
    function GetLastChild(ALine: Integer; ALevel: Integer): Integer;

    /// <summary>Find the parent line of a child line.</summary>
    function GetFoldParent(ALine: Integer): Integer;

    /// <summary>Is a line visible?</summary>
    function GetLineVisible(ALine: Integer): Boolean;

    /// <summary>Are all lines visible?</summary>
    function GetAllLinesVisible: Boolean;

    /// <summary>Show the children of a header line.</summary>
    procedure SetFoldExpanded(ALine: Integer; AExpanded: Boolean);

    /// <summary>Is a header line expanded?</summary>
    function GetFoldExpanded(ALine: Integer): Boolean;

    /// <summary>Set automatic folding behaviours.</summary>
    procedure SetAutomaticFold(AAutomaticFold: Integer);

    /// <summary>Get automatic folding behaviours.</summary>
    function GetAutomaticFold: Integer;

    /// <summary>Sets whether a tab pressed when caret is within indentation indents.</summary>
    procedure SetTabIndents(ATabIndents: Boolean);

    /// <summary>Does a tab pressed when caret is within indentation indent?</summary>
    function GetTabIndents: Boolean;

    /// <summary>Sets whether a backspace pressed when caret is within indentation unindents.</summary>
    procedure SetBackSpaceUnIndents(ABsUnIndents: Boolean);

    /// <summary>Does a backspace pressed when caret is within indentation unindent?</summary>
    function GetBackSpaceUnIndents: Boolean;

    /// <summary>Sets the time the mouse must sit still to generate a mouse dwell event.</summary>
    procedure SetMouseDwellTime(APeriodMilliseconds: Integer);

    /// <summary>Retrieve the time the mouse must sit still to generate a mouse dwell event.</summary>
    function GetMouseDwellTime: Integer;

    /// <summary>Sets whether text is word wrapped.</summary>
    procedure SetWrapMode(AMode: Integer);

    /// <summary>Retrieve whether text is word wrapped.</summary>
    function GetWrapMode: Integer;

    /// <summary>Set the display mode of visual flags for wrapped lines.</summary>
    procedure SetWrapVisualFlags(AWrapVisualFlags: Integer);

    /// <summary>Retrive the display mode of visual flags for wrapped lines.</summary>
    function GetWrapVisualFlags: Integer;

    /// <summary>Set the location of visual flags for wrapped lines.</summary>
    procedure SetWrapVisualFlagsLocation(AWrapVisualFlagsLocation: Integer);

    /// <summary>Retrive the location of visual flags for wrapped lines.</summary>
    function GetWrapVisualFlagsLocation: Integer;

    /// <summary>Set the start indent for wrapped lines.</summary>
    procedure SetWrapStartIndent(AIndent: Integer);

    /// <summary>Retrive the start indent for wrapped lines.</summary>
    function GetWrapStartIndent: Integer;

    /// <summary>Sets how wrapped sublines are placed. Default is fixed.</summary>
    procedure SetWrapIndentMode(AMode: Integer);

    /// <summary>Retrieve how wrapped sublines are placed. Default is fixed.</summary>
    function GetWrapIndentMode: Integer;

    /// <summary>Sets the degree of caching of layout information.</summary>
    procedure SetLayoutCache(AMode: Integer);

    /// <summary>Retrieve the degree of caching of layout information.</summary>
    function GetLayoutCache: Integer;

    /// <summary>Sets the document width assumed for scrolling.</summary>
    procedure SetScrollWidth(APixelWidth: Integer);

    /// <summary>Retrieve the document width assumed for scrolling.</summary>
    function GetScrollWidth: Integer;

    /// <summary>Sets whether the maximum width line displayed is used to set scroll width.</summary>
    procedure SetScrollWidthTracking(ATracking: Boolean);

    /// <summary>Retrieve whether the scroll width tracks wide lines.</summary>
    function GetScrollWidthTracking: Boolean;

    /// <summary>Sets the scroll range so that maximum scroll position has
    /// the last line at the bottom of the view (default).
    /// Setting this to false allows scrolling one page below the last line.</summary>
    procedure SetEndAtLastLine(AEndAtLastLine: Boolean);

    /// <summary>Retrieve whether the maximum scroll position has the last
    /// line at the bottom of the view.</summary>
    function GetEndAtLastLine: Boolean;

    /// <summary>Show or hide the vertical scroll bar.</summary>
    procedure SetVScrollBar(AShow: Boolean);

    /// <summary>Is the vertical scroll bar visible?</summary>
    function GetVScrollBar: Boolean;

    /// <summary>Is drawing done in two phases with backgrounds drawn before faoregrounds?</summary>
    function GetTwoPhaseDraw: Boolean;

    /// <summary>In twoPhaseDraw mode, drawing is performed in two phases, first the background
    /// and then the foreground. This avoids chopping off characters that overlap the next run.</summary>
    procedure SetTwoPhaseDraw(ATwoPhase: Boolean);

    /// <summary>Choose the quality level for text from the FontQuality enumeration.</summary>
    procedure SetFontQuality(AFontQuality: Integer);

    /// <summary>Retrieve the quality level for text.</summary>
    function GetFontQuality: Integer;

    /// <summary>Scroll so that a display line is at the top of the display.</summary>
    procedure SetFirstVisibleLine(ALineDisplay: Integer);

    /// <summary>Change the effect of pasting when there are multiple selections.</summary>
    procedure SetMultiPaste(AMultiPaste: Integer);

    /// <summary>Retrieve the effect of pasting when there are multiple selections..</summary>
    function GetMultiPaste: Integer;

    /// <summary>Are the end of line characters visible?</summary>
    function GetViewEOL: Boolean;

    /// <summary>Make the end of line characters visible or invisible.</summary>
    procedure SetViewEOL(AVisible: Boolean);

    /// <summary>Retrieve a pointer to the document object.</summary>
    function GetDocPointer: TDSciDocument;

    /// <summary>Change the document object used.</summary>
    procedure SetDocPointer(APointer: TDSciDocument);

    /// <summary>Set which document modification events are sent to the container.</summary>
    procedure SetModEventMask(AMask: Integer);

    /// <summary>Retrieve the column number which text should be kept within.</summary>
    function GetEdgeColumn: Integer;

    /// <summary>Set the column number of the edge.
    /// If text goes past the edge then it is highlighted.</summary>
    procedure SetEdgeColumn(AColumn: Integer);

    /// <summary>Retrieve the edge highlight mode.</summary>
    function GetEdgeMode: Integer;

    /// <summary>The edge may be displayed by a line (EDGE_LINE) or by highlighting text that
    /// goes beyond it (EDGE_BACKGROUND) or not displayed at all (EDGE_NONE).</summary>
    procedure SetEdgeMode(AMode: Integer);

    /// <summary>Retrieve the colour used in edge indication.</summary>
    function GetEdgeColour: TColor;

    /// <summary>Change the colour used in edge indication.</summary>
    procedure SetEdgeColour(AEdgeColour: TColor);

    /// <summary>Set the zoom level. This number of points is added to the size of all fonts.
    /// It may be positive to magnify or negative to reduce.</summary>
    procedure SetZoom(AZoom: Integer);

    /// <summary>Retrieve the zoom level.</summary>
    function GetZoom: Integer;

    /// <summary>Get which document modification events are sent to the container.</summary>
    function GetModEventMask: Integer;

    /// <summary>Change internal focus flag.</summary>
    procedure SetFocus(AFocus: Boolean); reintroduce; overload;

    /// <summary>Get internal focus flag.</summary>
    function GetFocus: Boolean;

    /// <summary>Change error status - 0 = OK.</summary>
    procedure SetStatus(AStatusCode: Integer);

    /// <summary>Get error status.</summary>
    function GetStatus: Integer;

    /// <summary>Set whether the mouse is captured when its button is pressed.</summary>
    procedure SetMouseDownCaptures(ACaptures: Boolean);

    /// <summary>Get whether mouse gets captured.</summary>
    function GetMouseDownCaptures: Boolean;

    /// <summary>Sets the cursor to one of the SC_CURSOR* values.</summary>
    procedure SetCursor(ACursorType: Integer);

    /// <summary>Get cursor type.</summary>
    function GetCursor: Integer;

    /// <summary>Change the way control characters are displayed:
    /// If symbol is &lt; 32, keep the drawn way, else, use the given character.</summary>
    procedure SetControlCharSymbol(ASymbol: Integer);

    /// <summary>Get the way control characters are displayed.</summary>
    function GetControlCharSymbol: Integer;

    /// <summary>Get and Set the xOffset (ie, horizontal scroll position).</summary>
    procedure SetXOffset(ANewOffset: Integer);

    function GetXOffset: Integer;

    /// <summary>Set printing to line wrapped (SC_WRAP_WORD) or not line wrapped (SC_WRAP_NONE).</summary>
    procedure SetPrintWrapMode(AMode: Integer);

    /// <summary>Is printing line wrapped?</summary>
    function GetPrintWrapMode: Integer;

    /// <summary>Set a fore colour for active hotspots.</summary>
    procedure SetHotspotActiveFore(AUseSetting: Boolean; AFore: TColor);

    /// <summary>Get the fore colour for active hotspots.</summary>
    function GetHotspotActiveFore: TColor;

    /// <summary>Set a back colour for active hotspots.</summary>
    procedure SetHotspotActiveBack(AUseSetting: Boolean; ABack: TColor);

    /// <summary>Get the back colour for active hotspots.</summary>
    function GetHotspotActiveBack: TColor;

    /// <summary>Enable / Disable underlining active hotspots.</summary>
    procedure SetHotspotActiveUnderline(AUnderline: Boolean);

    /// <summary>Get whether underlining for active hotspots.</summary>
    function GetHotspotActiveUnderline: Boolean;

    /// <summary>Limit hotspots to single line so hotspots on two lines don't merge.</summary>
    procedure SetHotspotSingleLine(ASingleLine: Boolean);

    /// <summary>Get the HotspotSingleLine property</summary>
    function GetHotspotSingleLine: Boolean;

    /// <summary>Set the selection mode to stream (SC_SEL_STREAM) or rectangular (SC_SEL_RECTANGLE/SC_SEL_THIN) or
    /// by lines (SC_SEL_LINES).</summary>
    procedure SetSelectionMode(AMode: Integer);

    /// <summary>Get the mode of the current selection.</summary>
    function GetSelectionMode: Integer;

    /// <summary>Set the set of characters making up whitespace for when moving or selecting by word.
    /// Should be called after SetWordChars.</summary>
    procedure SetWhitespaceChars(const ACharacters: UnicodeString);

    /// <summary>Get the set of characters making up whitespace for when moving or selecting by word.</summary>
    function GetWhitespaceChars: AnsiString;

    /// <summary>Set the set of characters making up punctuation characters
    /// Should be called after SetWordChars.</summary>
    procedure SetPunctuationChars(const ACharacters: AnsiString);

    /// <summary>Get the set of characters making up punctuation characters</summary>
    function GetPunctuationChars: AnsiString;

    /// <summary>Set auto-completion case insensitive behaviour to either prefer case-sensitive matches or have no preference.</summary>
    procedure AutoCSetCaseInsensitiveBehaviour(ABehaviour: Integer);

    /// <summary>Get auto-completion case insensitive behaviour.</summary>
    function AutoCGetCaseInsensitiveBehaviour: Integer;

    /// <summary>Set the way autocompletion lists are ordered.</summary>
    procedure AutoCSetOrder(AOrder: Integer);

    /// <summary>Get the way autocompletion lists are ordered.</summary>
    function AutoCGetOrder: Integer;

    /// <summary>Can the caret preferred x position only be changed by explicit movement commands?</summary>
    function GetCaretSticky: Integer;

    /// <summary>Stop the caret preferred x position changing when the user types.</summary>
    procedure SetCaretSticky(AUseCaretStickyBehaviour: Integer);

    /// <summary>Enable/Disable convert-on-paste for line endings</summary>
    procedure SetPasteConvertEndings(AConvert: Boolean);

    /// <summary>Get convert-on-paste setting</summary>
    function GetPasteConvertEndings: Boolean;

    /// <summary>Set background alpha of the caret line.</summary>
    procedure SetCaretLineBackAlpha(AAlpha: Integer);

    /// <summary>Get the background alpha of the caret line.</summary>
    function GetCaretLineBackAlpha: Integer;

    /// <summary>Set the style of the caret to be drawn.</summary>
    procedure SetCaretStyle(ACaretStyle: Integer);

    /// <summary>Returns the current style of the caret.</summary>
    function GetCaretStyle: Integer;

    /// <summary>Set the indicator used for IndicatorFillRange and IndicatorClearRange</summary>
    procedure SetIndicatorCurrent(AIndicator: Integer);

    /// <summary>Get the current indicator</summary>
    function GetIndicatorCurrent: Integer;

    /// <summary>Set the value used for IndicatorFillRange</summary>
    procedure SetIndicatorValue(AValue: Integer);

    /// <summary>Get the current indicator value</summary>
    function GetIndicatorValue: Integer;

    /// <summary>Set number of entries in position cache</summary>
    procedure SetPositionCache(ASize: Integer);

    /// <summary>How many entries are allocated to the position cache?</summary>
    function GetPositionCache: Integer;

    /// <summary>Compact the document buffer and return a read-only pointer to the
    /// characters in the document.</summary>
    function GetCharacterPointer: PByte;

    /// <summary>Return a read-only pointer to a range of characters in the document.
    /// May move the gap so that the range is contiguous, but will only move up
    /// to rangeLength bytes.</summary>
    function GetRangePointer(APosition: Integer; ARangeLength: Integer): Pointer;

    /// <summary>Always interpret keyboard input as Unicode</summary>
    procedure SetKeysUnicode(AKeysUnicode: Boolean);

    /// <summary>Are keys always interpreted as Unicode?</summary>
    function GetKeysUnicode: Boolean;

    /// <summary>Set the alpha fill colour of the given indicator.</summary>
    procedure IndicSetAlpha(AIndicator: Integer; AAlpha: Integer);

    /// <summary>Get the alpha fill colour of the given indicator.</summary>
    function IndicGetAlpha(AIndicator: Integer): Integer;

    /// <summary>Set the alpha outline colour of the given indicator.</summary>
    procedure IndicSetOutlineAlpha(AIndicator: Integer; AAlpha: Integer);

    /// <summary>Get the alpha outline colour of the given indicator.</summary>
    function IndicGetOutlineAlpha(AIndicator: Integer): Integer;

    /// <summary>Set extra ascent for each line</summary>
    procedure SetExtraAscent(AExtraAscent: Integer);

    /// <summary>Get extra ascent for each line</summary>
    function GetExtraAscent: Integer;

    /// <summary>Set extra descent for each line</summary>
    procedure SetExtraDescent(AExtraDescent: Integer);

    /// <summary>Get extra descent for each line</summary>
    function GetExtraDescent: Integer;

    /// <summary>Set the text in the text margin for a line</summary>
    procedure MarginSetText(ALine: Integer; const AText: UnicodeString);

    /// <summary>Get the text in the text margin for a line</summary>
    function MarginGetText(ALine: Integer): UnicodeString;

    /// <summary>Set the style number for the text margin for a line</summary>
    procedure MarginSetStyle(ALine: Integer; AStyle: Integer);

    /// <summary>Get the style number for the text margin for a line</summary>
    function MarginGetStyle(ALine: Integer): Integer;

    /// <summary>Set the style in the text margin for a line</summary>
    procedure MarginSetStyles(ALine: Integer; const AStyles: TDSciStyles);

    /// <summary>Get the styles in the text margin for a line</summary>
    function MarginGetStyles(ALine: Integer): TDSciStyles;

    /// <summary>Get the start of the range of style numbers used for margin text</summary>
    procedure MarginSetStyleOffset(AStyle: Integer);

    /// <summary>Get the start of the range of style numbers used for margin text</summary>
    function MarginGetStyleOffset: Integer;

    /// <summary>Set the margin options.</summary>
    procedure SetMarginOptions(AMarginOptions: Integer);

    /// <summary>Get the margin options.</summary>
    function GetMarginOptions: Integer;

    /// <summary>Set the annotation text for a line</summary>
    procedure AnnotationSetText(ALine: Integer; const AText: UnicodeString); overload;

    /// <summary>Get the annotation text for a line</summary>
    function AnnotationGetText(ALine: Integer): UnicodeString;

    /// <summary>Set the style number for the annotations for a line</summary>
    procedure AnnotationSetStyle(ALine: Integer; AStyle: Integer);

    /// <summary>Get the style number for the annotations for a line</summary>
    function AnnotationGetStyle(ALine: Integer): Integer;

    /// <summary>Set the annotation styles for a line</summary>
    procedure AnnotationSetStyles(ALine: Integer; const AStyles: TDSciStyles);

    /// <summary>Get the annotation styles for a line</summary>
    function AnnotationGetStyles(ALine: Integer): TDSciStyles;

    /// <summary>Get the number of annotation lines for a line</summary>
    function AnnotationGetLines(ALine: Integer): Integer;

    /// <summary>Set the visibility for the annotations for a view</summary>
    procedure AnnotationSetVisible(AVisible: Integer);

    /// <summary>Get the visibility for the annotations for a view</summary>
    function AnnotationGetVisible: Integer;

    /// <summary>Get the start of the range of style numbers used for annotations</summary>
    procedure AnnotationSetStyleOffset(AStyle: Integer);

    /// <summary>Get the start of the range of style numbers used for annotations</summary>
    function AnnotationGetStyleOffset: Integer;

    /// <summary>Set whether switching to rectangular mode while selecting with the mouse is allowed.</summary>
    procedure SetMouseSelectionRectangularSwitch(AMouseSelectionRectangularSwitch: Boolean);

    /// <summary>Whether switching to rectangular mode while selecting with the mouse is allowed.</summary>
    function GetMouseSelectionRectangularSwitch: Boolean;

    /// <summary>Set whether multiple selections can be made</summary>
    procedure SetMultipleSelection(AMultipleSelection: Boolean);

    /// <summary>Whether multiple selections can be made</summary>
    function GetMultipleSelection: Boolean;

    /// <summary>Set whether typing can be performed into multiple selections</summary>
    procedure SetAdditionalSelectionTyping(AAdditionalSelectionTyping: Boolean);

    /// <summary>Whether typing can be performed into multiple selections</summary>
    function GetAdditionalSelectionTyping: Boolean;

    /// <summary>Set whether additional carets will blink</summary>
    procedure SetAdditionalCaretsBlink(AAdditionalCaretsBlink: Boolean);

    /// <summary>Whether additional carets will blink</summary>
    function GetAdditionalCaretsBlink: Boolean;

    /// <summary>Set whether additional carets are visible</summary>
    procedure SetAdditionalCaretsVisible(AAdditionalCaretsBlink: Boolean);

    /// <summary>Whether additional carets are visible</summary>
    function GetAdditionalCaretsVisible: Boolean;

    /// <summary>How many selections are there?</summary>
    function GetSelections: Integer;

    /// <summary>Is every selected range empty?</summary>
    function GetSelectionEmpty: Boolean;

    /// <summary>Set the main selection</summary>
    procedure SetMainSelection(ASelection: Integer);

    /// <summary>Which selection is the main selection</summary>
    function GetMainSelection: Integer;

    procedure SetSelectionNCaret(ASelection: Integer; APos: Integer);

    function GetSelectionNCaret(ASelection: Integer): Integer;

    procedure SetSelectionNAnchor(ASelection: Integer; APosAnchor: Integer);

    function GetSelectionNAnchor(ASelection: Integer): Integer;

    procedure SetSelectionNCaretVirtualSpace(ASelection: Integer; ASpace: Integer);

    function GetSelectionNCaretVirtualSpace(ASelection: Integer): Integer;

    procedure SetSelectionNAnchorVirtualSpace(ASelection: Integer; ASpace: Integer);

    function GetSelectionNAnchorVirtualSpace(ASelection: Integer): Integer;

    /// <summary>Sets the position that starts the selection - this becomes the anchor.</summary>
    procedure SetSelectionNStart(ASelection: Integer; APos: Integer);

    /// <summary>Returns the position at the start of the selection.</summary>
    function GetSelectionNStart(ASelection: Integer): Integer;

    /// <summary>Sets the position that ends the selection - this becomes the currentPosition.</summary>
    procedure SetSelectionNEnd(ASelection: Integer; APos: Integer);

    /// <summary>Returns the position at the end of the selection.</summary>
    function GetSelectionNEnd(ASelection: Integer): Integer;

    procedure SetRectangularSelectionCaret(APos: Integer);

    function GetRectangularSelectionCaret: Integer;

    procedure SetRectangularSelectionAnchor(APosAnchor: Integer);

    function GetRectangularSelectionAnchor: Integer;

    procedure SetRectangularSelectionCaretVirtualSpace(ASpace: Integer);

    function GetRectangularSelectionCaretVirtualSpace: Integer;

    procedure SetRectangularSelectionAnchorVirtualSpace(ASpace: Integer);

    function GetRectangularSelectionAnchorVirtualSpace: Integer;

    procedure SetVirtualSpaceOptions(AVirtualSpaceOptions: Integer);

    function GetVirtualSpaceOptions: Integer;

    procedure SetRectangularSelectionModifier(AModifier: Integer);

    /// <summary>Get the modifier key used for rectangular selection.</summary>
    function GetRectangularSelectionModifier: Integer;

    /// <summary>Set the foreground colour of additional selections.
    /// Must have previously called SetSelFore with non-zero first argument for this to have an effect.</summary>
    procedure SetAdditionalSelFore(AFore: TColor);

    /// <summary>Set the background colour of additional selections.
    /// Must have previously called SetSelBack with non-zero first argument for this to have an effect.</summary>
    procedure SetAdditionalSelBack(ABack: TColor);

    /// <summary>Set the alpha of the selection.</summary>
    procedure SetAdditionalSelAlpha(AAlpha: Integer);

    /// <summary>Get the alpha of the selection.</summary>
    function GetAdditionalSelAlpha: Integer;

    /// <summary>Set the foreground colour of additional carets.</summary>
    procedure SetAdditionalCaretFore(AFore: TColor);

    /// <summary>Get the foreground colour of additional carets.</summary>
    function GetAdditionalCaretFore: TColor;

    /// <summary>Set the identifier reported as idFrom in notification messages.</summary>
    procedure SetIdentifier(AIdentifier: Integer);

    /// <summary>Get the identifier.</summary>
    function GetIdentifier: Integer;

    /// <summary>Set the width for future RGBA image data.</summary>
    procedure RGBAImageSetWidth(AWidth: Integer);

    /// <summary>Set the height for future RGBA image data.</summary>
    procedure RGBAImageSetHeight(AHeight: Integer);

    /// <summary>Set the technology used.</summary>
    procedure SetTechnology(ATechnology: Integer);

    /// <summary>Get the tech.</summary>
    function GetTechnology: Integer;

    /// <summary>Is the caret line always visible?</summary>
    function GetCaretLineVisibleAlways: Boolean;

    /// <summary>Sets the caret line to always visible.</summary>
    procedure SetCaretLineVisibleAlways(AAlwaysVisible: Boolean);

    /// <summary>Set the line end types that the application wants to use. May not be used if incompatible with lexer or encoding.</summary>
    procedure SetLineEndTypesAllowed(ALineEndBitSet: Integer);

    /// <summary>Get the line end types currently allowed.</summary>
    function GetLineEndTypesAllowed: Integer;

    /// <summary>Get the line end types currently recognised. May be a subset of the allowed types due to lexer limitation.</summary>
    function GetLineEndTypesActive: Integer;

    /// <summary>Set the way a character is drawn.</summary>
    procedure SetRepresentation(AEncodedCharacter: AnsiString; ARepresentation: AnsiString);

    /// <summary>Set the way a character is drawn.</summary>
    function GetRepresentation(AEncodedCharacter: AnsiString): AnsiString;

    /// <summary>Set the lexing language of the document.</summary>
    procedure SetLexer(ALexer: Integer);

    /// <summary>Retrieve the lexing language of the document.</summary>
    function GetLexer: Integer;

    /// <summary>Set up a value that may be used by a lexer for some optional feature.</summary>
    procedure SetProperty(const AKey: UnicodeString; const AValue: UnicodeString);

    /// <summary>Retrieve a "property" value previously set with SetProperty,
    /// interpreted as an int AFTER any "$()" variable replacement.</summary>
    function GetPropertyInt(const AKey: UnicodeString; ADefault: Integer): Integer;

    /// <summary>Retrieve the number of bits the current lexer needs for styling.</summary>
    function GetStyleBitsNeeded: Integer;

    /// <summary>Retrieve the name of the lexer.
    /// Return the length of the text.</summary>
    function GetLexerLanguage: UnicodeString;

    /// <summary>Bit set of LineEndType enumertion for which line ends beyond the standard
    /// LF, CR, and CRLF are supported by the lexer.</summary>
    function GetLineEndTypesSupported: Integer;

    /// <summary>The starting style number for the sub styles associated with a base style</summary>
    function GetSubStylesStart(AStyleBase: Integer): Integer;

    /// <summary>The number of sub styles associated with a base style</summary>
    function GetSubStylesLength(AStyleBase: Integer): Integer;

    /// <summary>For a sub style, return the base style, else return the argument.</summary>
    function GetStyleFromSubStyle(ASubStyle: Integer): Integer;

    /// <summary>For a secondary style, return the primary style, else return the argument.</summary>
    function GetPrimaryStyleFromStyle(AStyle: Integer): Integer;

    /// <summary>Set the identifiers that are shown in a particular style</summary>
    procedure SetIdentifiers(AStyle: Integer; const AIdentifiers: AnsiString);

    /// <summary>Where styles are duplicated by a feature such as active/inactive code
    /// return the distance between the two types.</summary>
    function DistanceToSecondaryStyles: Integer;

    /// <summary>Get the set of base styles that can be extended with sub styles</summary>
    function GetSubStyleBases: UnicodeString;

    /// <summary>Deprecated in 2.30
    /// In palette mode?</summary>
    // function GetUsePalette: Boolean;

    /// <summary>Deprecated in 2.30
    /// In palette mode, Scintilla uses the environment's palette calls to display
    /// more colours. This may lead to ugly displays.</summary>
    // procedure SetUsePalette(AUsePalette: Boolean);

    /// <summary>Clear the annotation text for a line</summary>
    procedure AnnotationSetText(ALine: Integer); overload;
{$ENDREGION 'Scintilla properties'}
//    {$I DScintillaPropertiesDecl.inc}

    /// <summary>Calls TWinControl.SetFocus</summary>
    procedure SetFocus; reintroduce; overload;

    procedure EnsureRangeVisible(APosStart, APosEnd: Integer);

  published

    property Lines: TDSciLines read FLines write SetLines;

    // Called after when window is created or recreated
    property OnInitDefaults: TNotifyEvent read FOnInitDefaults write FOnInitDefaults;

    // Deprecated
    property OnStoreDocState: TNotifyEvent read FOnStoreDocState write FOnStoreDocState;
    property OnRestoreDocState: TNotifyEvent read FOnRestoreDocState write FOnRestoreDocState;

    // Scintilla events - see documentation at http://www.scintilla.org/ScintillaDoc.html#Notifications

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnSCNotificationEvent: TDSciNotificationEvent read FOnSCNotificationEvent write FOnSCNotificationEvent;

    property OnStyleNeeded: TDSciStyleNeededEvent read FOnStyleNeeded write FOnStyleNeeded;
    property OnCharAdded: TDSciCharAddedEvent read FOnCharAdded write FOnCharAdded;
    property OnSavePointReached: TDSciSavePointReachedEvent read FOnSavePointReached write FOnSavePointReached;
    property OnSavePointLeft: TDSciSavePointLeftEvent read FOnSavePointLeft write FOnSavePointLeft;
    property OnModifyAttemptRO: TDSciModifyAttemptROEvent read FOnModifyAttemptRO write FOnModifyAttemptRO;
    property OnUpdateUI: TDSciUpdateUIEvent read FOnUpdateUI write FOnUpdateUI;
    property OnModified: TDSciModifiedEvent read FOnModified write FOnModified; // deprecated - use OnModified2
    property OnModified2: TDSciModified2Event read FOnModified2 write FOnModified2;
    property OnMacroRecord: TDSciMacroRecordEvent read FOnMacroRecord write FOnMacroRecord;
    property OnMarginClick: TDSciMarginClickEvent read FOnMarginClick write FOnMarginClick;

    // Note: if you are using OnNeedShown, then you must perform similar task as in DoNeedShown
    // In general you need to call EnsureRangeVisible(...)
    // See: https://code.google.com/p/dscintilla/issues/detail?id=4
    property OnNeedShown: TDSciNeedShownEvent read FOnNeedShown write FOnNeedShown;
    property OnPainted: TDSciPaintedEvent read FOnPainted write FOnPainted;
    property OnUserListSelection: TDSciUserListSelectionEvent read FOnUserListSelection write FOnUserListSelection; // deprecated - use OnUserListSelection2
    property OnUserListSelection2: TDSciUserListSelection2Event read FOnUserListSelection2 write FOnUserListSelection2;
    property OnDwellStart: TDSciDwellStartEvent read FOnDwellStart write FOnDwellStart;
    property OnDwellEnd: TDSciDwellEndEvent read FOnDwellEnd write FOnDwellEnd;
    property OnZoom: TDSciZoomEvent read FOnZoom write FOnZoom;
    property OnHotSpotClick: TDSciHotSpotClickEvent read FOnHotSpotClick write FOnHotSpotClick;
    property OnHotSpotDoubleClick: TDSciHotSpotDoubleClickEvent read FOnHotSpotDoubleClick write FOnHotSpotDoubleClick;
    property OnHotSpotReleaseClick: TDSciHotSpotReleaseClickEvent read FOnHotSpotReleaseClick write FOnHotSpotReleaseClick;
    property OnCallTipClick: TDSciCallTipClickEvent read FOnCallTipClick write FOnCallTipClick;
    property OnAutoCSelection: TDSciAutoCSelectionEvent read FOnAutoCSelection write FOnAutoCSelection;
    property OnIndicatorClick: TDSciIndicatorClickEvent read FOnIndicatorClick write FOnIndicatorClick;
    property OnIndicatorRelease: TDSciIndicatorReleaseEvent read FOnIndicatorRelease write FOnIndicatorRelease;
    property OnAutoCCancelled: TDSciAutoCCancelledEvent read FOnAutoCCancelled write FOnAutoCCancelled;
    property OnAutoCCharDeleted: TDSciAutoCCharDeletedEvent read FOnAutoCCharDeleted write FOnAutoCCharDeleted;
  end;

implementation

{ TDScintilla }

constructor TDScintilla.Create(AOwner: TComponent);
begin
  FHelper := TDSciHelper.Create(SendEditor);
  FLines := TDSciLines.Create(FHelper);

  inherited Create(AOwner);
end;

destructor TDScintilla.Destroy;
begin
  inherited Destroy;

  FreeAndNil(FLines);
  FreeAndNil(FHelper);
end;

procedure TDScintilla.SetLines(const Value: TDSciLines);
begin
  FLines.Assign(Value);
end;

procedure TDScintilla.CreateWnd;
var
  lIsRecreating: Boolean;
begin
  lIsRecreating := IsRecreatingWnd;

  inherited CreateWnd;

  if not lIsRecreating then
  begin
    // Set UTF8 early, so Lines with non ANSI char loads from .dfm correctly
    // Later in InitDefaults/OnInitDefaults can be overwritten
    SetCodePage(SC_CP_UTF8);

    // Delay calling DoInitDefaults when loading component from .dfm
    // OnInitDefaults might not be set yet, so you can miss this event
    FInitDefaultsDelayed := csLoading in ComponentState;
    if not FInitDefaultsDelayed then
      DoInitDefaults;
  end;
end;

procedure TDScintilla.Loaded;
begin
  inherited Loaded;

  if FInitDefaultsDelayed then
  begin
    FInitDefaultsDelayed := False;
    DoInitDefaults;
  end;
end;

procedure TDScintilla.InitDefaults;
begin
  // By default set Unicode-UTF8 mode
  SetKeysUnicode(True);
  SetCodePage(SC_CP_UTF8);
end;

procedure TDScintilla.DoInitDefaults;
begin
  InitDefaults;

  { If anywhere in the parent control hierarchy a reparenting operation
    is performed, this can lead to the Scintilla handle being destroyed
    (and later recreated). This in turn leads to loss of styles etc.,
    which is pretty bad. This event gives the caller a chance to
    reinitialize all that stuff. }
  if Assigned(OnInitDefaults) then
    OnInitDefaults(Self);
end;

procedure TDScintilla.CNNotify(var AMessage: TWMNotify);
begin
  if HandleAllocated and (AMessage.NMHdr^.hwndFrom = Self.Handle) then
    DoSCNotification(PDSciSCNotification(AMessage.NMHdr)^)
  else
    inherited;
end;

procedure TDScintilla.CNCommand(var AMessage: TWMCommand);
begin
  if AMessage.NotifyCode = SCEN_CHANGE then
  begin
    if Assigned(OnChange) then
      OnChange(Self);
  end else
    inherited;
end;

procedure TDScintilla.DoNeedShown(const ASCNotification: TDSciSCNotification);
begin
  if Assigned(FOnNeedShown) then
    FOnNeedShown(Self, ASCNotification.position, ASCNotification.length)
  else
  begin
    // Fix for: https://code.google.com/p/dscintilla/issues/detail?id=4
    //
    // SciTE does same thing: scite/src/SciTEBase.cxx ... case SCN_NEEDSHOWN: { ...
    // Also docs tells that it need to be done:
    // http://www.scintilla.org/ScintillaDoc.html#SCN_NEEDSHOWN
    EnsureRangeVisible(ASCNotification.position, ASCNotification.position + ASCNotification.length);
  end;
end;

function TDScintilla.DoSCNotification(const ASCNotification: TDSciSCNotification): Boolean;
begin
  Result := False;

  if Assigned(FOnSCNotificationEvent) then
    FOnSCNotificationEvent(Self, ASCNotification, Result);

  if Result then
    Exit;

  Result := True;

  case ASCNotification.NotifyHeader.code of
  SCN_STYLENEEDED:
    if Assigned(FOnStyleNeeded) then
      FOnStyleNeeded(Self, ASCNotification.position);

  SCN_CHARADDED:
    if Assigned(FOnCharAdded) then
      FOnCharAdded(Self, ASCNotification.ch);

  SCN_SAVEPOINTREACHED:
    if Assigned(FOnSavePointReached) then
      FOnSavePointReached(Self);

  SCN_SAVEPOINTLEFT:
    if Assigned(FOnSavePointLeft) then
      FOnSavePointLeft(Self);

  SCN_MODIFYATTEMPTRO:
    if Assigned(FOnModifyAttemptRO) then
      FOnModifyAttemptRO(Self);

  SCN_UPDATEUI:
    if Assigned(FOnUpdateUI) then
      FOnUpdateUI(Self, ASCNotification.updated);

  SCN_MODIFIED:
    begin
      if Assigned(FOnModified) then
        FOnModified(Self, ASCNotification.position, ASCNotification.modificationType,
          FHelper.GetStrFromPtr(ASCNotification.text), ASCNotification.length,
          ASCNotification.linesAdded, ASCNotification.line,
          ASCNotification.foldLevelNow, ASCNotification.foldLevelPrev);

      if Assigned(FOnModified2) then
        FOnModified2(Self, ASCNotification.position, ASCNotification.modificationType,
          FHelper.GetStrFromPtr(ASCNotification.text), ASCNotification.length,
          ASCNotification.linesAdded, ASCNotification.line,
          ASCNotification.foldLevelNow, ASCNotification.foldLevelPrev,
          ASCNotification.token, ASCNotification.annotationLinesAdded);
    end;

  SCN_MACRORECORD:
    if Assigned(FOnMacroRecord) then
      FOnMacroRecord(Self, ASCNotification.message, ASCNotification.wParam,
        ASCNotification.lParam);

  SCN_MARGINCLICK:
    if Assigned(FOnMarginClick) then
      FOnMarginClick(Self, ASCNotification.modifiers,
        ASCNotification.position, ASCNotification.margin);

  SCN_NEEDSHOWN:
    DoNeedShown(ASCNotification);

  SCN_PAINTED:
    if Assigned(FOnPainted) then
      FOnPainted(Self);

  SCN_USERLISTSELECTION:
    begin
      if Assigned(FOnUserListSelection) then
        FOnUserListSelection(Self, ASCNotification.listType,
          FHelper.GetStrFromPtr(ASCNotification.text));

      if Assigned(FOnUserListSelection2) then
        FOnUserListSelection2(Self, ASCNotification.listType,
          FHelper.GetStrFromPtr(ASCNotification.text),
          ASCNotification.position);
    end;

  SCN_DWELLSTART:
    if Assigned(FOnDwellStart) then
      FOnDwellStart(Self, ASCNotification.position, ASCNotification.x, ASCNotification.y);

  SCN_DWELLEND:
    if Assigned(FOnDwellEnd) then
      FOnDwellEnd(Self, ASCNotification.position, ASCNotification.x, ASCNotification.y);

  SCN_ZOOM:
    if Assigned(FOnZoom) then
      FOnZoom(Self);

  SCN_HOTSPOTCLICK:
    if Assigned(FOnHotSpotClick) then
      FOnHotSpotClick(Self, ASCNotification.modifiers, ASCNotification.position);

  SCN_HOTSPOTDOUBLECLICK:
    if Assigned(FOnHotSpotDoubleClick) then
      FOnHotSpotDoubleClick(Self, ASCNotification.modifiers, ASCNotification.position);

  SCN_HOTSPOTRELEASECLICK:
    if Assigned(FOnHotSpotReleaseClick) then
      FOnHotSpotReleaseClick(Self, ASCNotification.modifiers, ASCNotification.position);

  SCN_CALLTIPCLICK:
    if Assigned(FOnCallTipClick) then
      FOnCallTipClick(Self, ASCNotification.position);

  SCN_AUTOCSELECTION:
    if Assigned(FOnAutoCSelection) then
      FOnAutoCSelection(Self, FHelper.GetStrFromPtr(ASCNotification.text),
        ASCNotification.lParam);

  SCN_INDICATORCLICK:
    if Assigned(FOnIndicatorClick) then
      FOnIndicatorClick(Self, ASCNotification.modifiers, ASCNotification.position);

  SCN_INDICATORRELEASE:
    if Assigned(FOnIndicatorRelease) then
      FOnIndicatorRelease(Self, ASCNotification.modifiers, ASCNotification.position);

  SCN_AUTOCCANCELLED:
    if Assigned(FOnAutoCCancelled) then
      FOnAutoCCancelled(Self);

  SCN_AUTOCCHARDELETED:
    if Assigned(FOnAutoCCharDeleted) then
      FOnAutoCCharDeleted(Self);
  else
    Result := False;
  end;
end;

// -----------------------------------------------------------------------------
// Scintilla methods -----------------------------------------------------------
// -----------------------------------------------------------------------------
{$REGION 'Scintilla methods CODE'}

procedure TDScintilla.AddText(const AText: UnicodeString);
begin
  FHelper.SetTextLen(SCI_ADDTEXT, AText);
end;

procedure TDScintilla.AddStyledText(const ACells: TDSciCells);
begin
  SendEditor(SCI_ADDSTYLEDTEXT, System.Length(ACells) * 2, Integer(ACells));
end;

procedure TDScintilla.InsertText(APos: Integer; const AText: UnicodeString);
begin
  FHelper.SetText(SCI_INSERTTEXT, APos, AText);
end;

procedure TDScintilla.ChangeInsertion(const AText: UnicodeString);
begin
  FHelper.SetTextLen(SCI_CHANGEINSERTION, AText);
end;

procedure TDScintilla.ClearAll;
begin
  SendEditor(SCI_CLEARALL, 0, 0);
end;

procedure TDScintilla.DeleteRange(APos: Integer; ADeleteLength: Integer);
begin
  SendEditor(SCI_DELETERANGE, APos, ADeleteLength);
end;

procedure TDScintilla.ClearDocumentStyle;
begin
  SendEditor(SCI_CLEARDOCUMENTSTYLE, 0, 0);
end;

procedure TDScintilla.Redo;
begin
  SendEditor(SCI_REDO, 0, 0);
end;

procedure TDScintilla.SelectAll;
begin
  SendEditor(SCI_SELECTALL, 0, 0);
end;

procedure TDScintilla.SetSavePoint;
begin
  SendEditor(SCI_SETSAVEPOINT, 0, 0);
end;

function TDScintilla.GetStyledText(AStart, AEnd: Integer): TDSciCells;
var
  lRange: TDSciTextRange;
begin
  if AStart >= AEnd then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Result, AEnd - AStart + 1{nul});

  lRange.chrg.cpMin := AStart;
  lRange.chrg.cpMax := AEnd;
  lRange.lpstrText := @Result[0];

  SendEditor(SCI_GETSTYLEDTEXT, 0, Integer(@lRange));
end;

function TDScintilla.CanRedo: Boolean;
begin
  Result := Boolean(SendEditor(SCI_CANREDO, 0, 0));
end;

function TDScintilla.MarkerLineFromHandle(AHandle: Integer): Integer;
begin
  Result := SendEditor(SCI_MARKERLINEFROMHANDLE, AHandle, 0);
end;

procedure TDScintilla.MarkerDeleteHandle(AHandle: Integer);
begin
  SendEditor(SCI_MARKERDELETEHANDLE, AHandle, 0);
end;

function TDScintilla.PositionFromPoint(AX: Integer; AY: Integer): Integer;
begin
  Result := SendEditor(SCI_POSITIONFROMPOINT, AX, AY);
end;

function TDScintilla.PositionFromPointClose(AX: Integer; AY: Integer): Integer;
begin
  Result := SendEditor(SCI_POSITIONFROMPOINTCLOSE, AX, AY);
end;

procedure TDScintilla.GotoLine(ALine: Integer);
begin
  SendEditor(SCI_GOTOLINE, ALine, 0);
end;

procedure TDScintilla.GotoPos(APos: Integer);
begin
  SendEditor(SCI_GOTOPOS, APos, 0);
end;

function TDScintilla.GetCurLine(var AText: UnicodeString): Integer;
begin
  Result := FHelper.GetTextLen(SCI_GETCURLINE, AText);
end;

procedure TDScintilla.ConvertEOLs(AEolMode: Integer);
begin
  SendEditor(SCI_CONVERTEOLS, AEolMode, 0);
end;

procedure TDScintilla.StartStyling(APos: Integer; AMask: Integer);
begin
  SendEditor(SCI_STARTSTYLING, APos, AMask);
end;

procedure TDScintilla.SetStyling(ALength: Integer; AStyle: Integer);
begin
  SendEditor(SCI_SETSTYLING, ALength, AStyle);
end;

procedure TDScintilla.MarkerDefine(AMarkerNumber: Integer; AMarkerSymbol: Integer);
begin
  SendEditor(SCI_MARKERDEFINE, AMarkerNumber, AMarkerSymbol);
end;

procedure TDScintilla.MarkerSetFore(AMarkerNumber: Integer; AFore: TColor);
begin
  SendEditor(SCI_MARKERSETFORE, AMarkerNumber, Integer(AFore));
end;

procedure TDScintilla.MarkerSetBack(AMarkerNumber: Integer; ABack: TColor);
begin
  SendEditor(SCI_MARKERSETBACK, AMarkerNumber, Integer(ABack));
end;

procedure TDScintilla.MarkerSetBackSelected(AMarkerNumber: Integer; ABack: TColor);
begin
  SendEditor(SCI_MARKERSETBACKSELECTED, AMarkerNumber, Integer(ABack));
end;

procedure TDScintilla.MarkerEnableHighlight(AEnabled: Boolean);
begin
  SendEditor(SCI_MARKERENABLEHIGHLIGHT, Integer(AEnabled), 0);
end;

function TDScintilla.MarkerAdd(ALine: Integer; AMarkerNumber: Integer): Integer;
begin
  Result := SendEditor(SCI_MARKERADD, ALine, AMarkerNumber);
end;

procedure TDScintilla.MarkerDelete(ALine: Integer; AMarkerNumber: Integer);
begin
  SendEditor(SCI_MARKERDELETE, ALine, AMarkerNumber);
end;

procedure TDScintilla.MarkerDeleteAll(AMarkerNumber: Integer);
begin
  SendEditor(SCI_MARKERDELETEALL, AMarkerNumber, 0);
end;

function TDScintilla.MarkerGet(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_MARKERGET, ALine, 0);
end;

function TDScintilla.MarkerNext(ALineStart: Integer; AMarkerMask: Integer): Integer;
begin
  Result := SendEditor(SCI_MARKERNEXT, ALineStart, AMarkerMask);
end;

function TDScintilla.MarkerPrevious(ALineStart: Integer; AMarkerMask: Integer): Integer;
begin
  Result := SendEditor(SCI_MARKERPREVIOUS, ALineStart, AMarkerMask);
end;

procedure TDScintilla.MarkerDefinePixmap(AMarkerNumber: Integer; const APixmap: TBytes);
begin
  SendEditor(SCI_MARKERDEFINEPIXMAP, AMarkerNumber, NativeInt(APixmap));
end;

procedure TDScintilla.MarkerAddSet(ALine: Integer; ASet: Integer);
begin
  SendEditor(SCI_MARKERADDSET, ALine, ASet);
end;

procedure TDScintilla.MarkerSetAlpha(AMarkerNumber: Integer; AAlpha: Integer);
begin
  SendEditor(SCI_MARKERSETALPHA, AMarkerNumber, AAlpha);
end;

procedure TDScintilla.StyleClearAll;
begin
  SendEditor(SCI_STYLECLEARALL, 0, 0);
end;

procedure TDScintilla.StyleResetDefault;
begin
  SendEditor(SCI_STYLERESETDEFAULT, 0, 0);
end;

function TDScintilla.StyleGetFont(AStyle: Integer): UnicodeString;
begin
  FHelper.GetText(SCI_STYLEGETFONT, AStyle, Result);
end;

procedure TDScintilla.SetSelFore(AUseSetting: Boolean; AFore: TColor);
begin
  SendEditor(SCI_SETSELFORE, Integer(AUseSetting), Integer(AFore));
end;

procedure TDScintilla.SetSelBack(AUseSetting: Boolean; ABack: TColor);
begin
  SendEditor(SCI_SETSELBACK, Integer(AUseSetting), Integer(ABack));
end;

procedure TDScintilla.AssignCmdKey(AKm: Integer; AMsg: Integer);
begin
  SendEditor(SCI_ASSIGNCMDKEY, AKm, AMsg);
end;

procedure TDScintilla.ClearCmdKey(AKm: Integer);
begin
  SendEditor(SCI_CLEARCMDKEY, AKm, 0);
end;

procedure TDScintilla.ClearAllCmdKeys;
begin
  SendEditor(SCI_CLEARALLCMDKEYS, 0, 0);
end;

procedure TDScintilla.SetStylingEx(const AStyles: TDSciStyles);
begin
  SendEditor(SCI_SETSTYLINGEX, System.Length(AStyles), Integer(AStyles));
end;

procedure TDScintilla.BeginUndoAction;
begin
  SendEditor(SCI_BEGINUNDOACTION, 0, 0);
end;

procedure TDScintilla.EndUndoAction;
begin
  SendEditor(SCI_ENDUNDOACTION, 0, 0);
end;

procedure TDScintilla.SetWhitespaceFore(AUseSetting: Boolean; AFore: TColor);
begin
  SendEditor(SCI_SETWHITESPACEFORE, Integer(AUseSetting), Integer(AFore));
end;

procedure TDScintilla.SetWhitespaceBack(AUseSetting: Boolean; ABack: TColor);
begin
  SendEditor(SCI_SETWHITESPACEBACK, Integer(AUseSetting), Integer(ABack));
end;

procedure TDScintilla.AutoCShow(ALenEntered: Integer; const AItemList: UnicodeString);
begin
  FHelper.SetText(SCI_AUTOCSHOW, ALenEntered, AItemList);
end;

procedure TDScintilla.AutoCCancel;
begin
  SendEditor(SCI_AUTOCCANCEL, 0, 0);
end;

function TDScintilla.AutoCActive: Boolean;
begin
  Result := Boolean(SendEditor(SCI_AUTOCACTIVE, 0, 0));
end;

function TDScintilla.AutoCPosStart: Integer;
begin
  Result := SendEditor(SCI_AUTOCPOSSTART, 0, 0);
end;

procedure TDScintilla.AutoCComplete;
begin
  SendEditor(SCI_AUTOCCOMPLETE, 0, 0);
end;

procedure TDScintilla.AutoCStops(const ACharacterSet: UnicodeString);
begin
  FHelper.SetText(SCI_AUTOCSTOPS, 0, ACharacterSet);
end;

procedure TDScintilla.AutoCSelect(const AText: UnicodeString);
begin
  FHelper.SetText(SCI_AUTOCSELECT, 0, AText);
end;

procedure TDScintilla.UserListShow(AListType: Integer; const AItemList: UnicodeString);
begin
  FHelper.SetText(SCI_USERLISTSHOW, AListType, AItemList);
end;

procedure TDScintilla.RegisterImage(AType: Integer; const AXpmData: TBytes);
begin
  if Length(AXpmData) > 0 then
    SendEditor(SCI_REGISTERIMAGE, AType, NativeInt(AXpmData));
end;

procedure TDScintilla.ClearRegisteredImages;
begin
  SendEditor(SCI_CLEARREGISTEREDIMAGES, 0, 0);
end;

function TDScintilla.CountCharacters(AStartPos: Integer; AEndPos: Integer): Integer;
begin
  Result := SendEditor(SCI_COUNTCHARACTERS, AStartPos, AEndPos);
end;

procedure TDScintilla.SetEmptySelection(APos: Integer);
begin
  SendEditor(SCI_SETEMPTYSELECTION, APos, 0);
end;

function TDScintilla.FindText(AFlags: Integer; const AText: UnicodeString; var ARange: TDSciCharacterRange): Integer;
var
  lRange: TDSciTextToFind;
begin
  lRange.chrg := ARange;
  if SendEditor(SCI_GETCODEPAGE) = SC_CP_UTF8 then
  begin
    lRange.lpstrText := PAnsiChar(UnicodeStringToUTF8(AText));
    Result := SendEditor(SCI_FINDTEXT, AFlags, Integer(@lRange));
  end else
  begin
    lRange.lpstrText := PAnsiChar(AnsiString(AText));
    Result := SendEditor(SCI_FINDTEXT, AFlags, Integer(@lRange));
  end;

  if Result > INVALID_POSITION then
    ARange := lRange.chrgText;
end;

function TDScintilla.FormatRange(ADraw: Boolean; var AFr: TDSciRangeToFormat): Integer;
begin
  Result := SendEditor(SCI_FORMATRANGE, Integer(ADraw), Integer(@AFr));
end;

function TDScintilla.GetLine(ALine: Integer): UnicodeString;
begin
  FHelper.GetText(SCI_GETLINE, ALine, Result);
end;

procedure TDScintilla.SetSel(AStart: Integer; AEnd: Integer);
begin
  SendEditor(SCI_SETSEL, AStart, AEnd);
end;

function TDScintilla.GetSelText: UnicodeString;
begin
  FHelper.GetText(SCI_GETSELTEXT, 0, Result);
end;

function TDScintilla.GetTextRange(AStart, AEnd: Integer): UnicodeString;
var
  lRange: TDSciTextRange;
  lChars: TDSciChars;
  lActualLength: Integer;
begin
  Result := '';

  if AEnd = -1 then
    AEnd := GetLength
  else
    if AEnd > GetLength then
      Exit;

  if (AStart < 0) or (AEnd < 0) or (AStart >= AEnd) then
    Exit;

  SetLength(lChars, AEnd - AStart + 1); // to handle case when text is zero-terminated, as per the Scintilla docs for SCI_GETTEXTRANGE

  lRange.chrg.cpMin := AStart;
  lRange.chrg.cpMax := AEnd;
  lRange.lpstrText := @lChars[0];

  lActualLength := SendEditor(SCI_GETTEXTRANGE, 0, Integer(@lRange));
  lChars[lActualLength] := #0;

  Result := FHelper.GetStrFromPtr(@lChars[0]);
end;

procedure TDScintilla.HideSelection(ANormal: Boolean);
begin
  SendEditor(SCI_HIDESELECTION, Integer(ANormal), 0);
end;

function TDScintilla.PointXFromPosition(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_POINTXFROMPOSITION, 0, APos);
end;

function TDScintilla.PointYFromPosition(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_POINTYFROMPOSITION, 0, APos);
end;

function TDScintilla.LineFromPosition(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_LINEFROMPOSITION, APos, 0);
end;

function TDScintilla.PositionFromLine(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_POSITIONFROMLINE, ALine, 0);
end;

procedure TDScintilla.LineScroll(AColumns: Integer; ALines: Integer);
begin
  SendEditor(SCI_LINESCROLL, AColumns, ALines);
end;

procedure TDScintilla.ScrollCaret;
begin
  SendEditor(SCI_SCROLLCARET, 0, 0);
end;

procedure TDScintilla.ScrollRange(ASecondary: Integer; APrimary: Integer);
begin
  SendEditor(SCI_SCROLLRANGE, ASecondary, APrimary);
end;

procedure TDScintilla.ReplaceSel(const AText: UnicodeString);
begin
  FHelper.SetText(SCI_REPLACESEL, 0, AText);
end;

// procedure TDScintilla.Null;
// begin
//   SendEditor(SCI_NULL, 0, 0);
// end;

function TDScintilla.CanPaste: Boolean;
begin
  Result := Boolean(SendEditor(SCI_CANPASTE, 0, 0));
end;

function TDScintilla.CanUndo: Boolean;
begin
  Result := Boolean(SendEditor(SCI_CANUNDO, 0, 0));
end;

procedure TDScintilla.EmptyUndoBuffer;
begin
  SendEditor(SCI_EMPTYUNDOBUFFER, 0, 0);
end;

procedure TDScintilla.Undo;
begin
  SendEditor(SCI_UNDO, 0, 0);
end;

procedure TDScintilla.Cut;
begin
  SendEditor(SCI_CUT, 0, 0);
end;

procedure TDScintilla.Copy;
begin
  SendEditor(SCI_COPY, 0, 0);
end;

procedure TDScintilla.Paste;
begin
  SendEditor(SCI_PASTE, 0, 0);
end;

procedure TDScintilla.Clear;
begin
  SendEditor(SCI_CLEAR, 0, 0);
end;

procedure TDScintilla.SetText(const AText: UnicodeString);
begin
  FHelper.SetText(SCI_SETTEXT, 0, AText);
end;

function TDScintilla.GetText: UnicodeString;
begin
  FHelper.GetTextLen(SCI_GETTEXT, Result);
end;

function TDScintilla.ReplaceTarget(const AText: UnicodeString): Integer;
begin
  Result := FHelper.SetTextLen(SCI_REPLACETARGET, AText);
end;

function TDScintilla.ReplaceTargetRE(const AText: UnicodeString): Integer;
begin
  Result := FHelper.SetTextLen(SCI_REPLACETARGETRE, AText);
end;

function TDScintilla.SearchInTarget(const AText: UnicodeString): Integer;
begin
  Result := FHelper.SetTextLen(SCI_SEARCHINTARGET, AText);
end;

procedure TDScintilla.CallTipShow(APos: Integer; const ADefinition: UnicodeString);
begin
  if ADefinition = '' then
    CallTipCancel
  else
    FHelper.SetText(SCI_CALLTIPSHOW, APos, ADefinition);
end;

procedure TDScintilla.CallTipCancel;
begin
  SendEditor(SCI_CALLTIPCANCEL, 0, 0);
end;

function TDScintilla.CallTipActive: Boolean;
begin
  Result := Boolean(SendEditor(SCI_CALLTIPACTIVE, 0, 0));
end;

function TDScintilla.CallTipPosStart: Integer;
begin
  Result := SendEditor(SCI_CALLTIPPOSSTART, 0, 0);
end;

procedure TDScintilla.CallTipSetHlt(AStart: Integer; AEnd: Integer);
begin
  SendEditor(SCI_CALLTIPSETHLT, AStart, AEnd);
end;

function TDScintilla.VisibleFromDocLine(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_VISIBLEFROMDOCLINE, ALine, 0);
end;

function TDScintilla.DocLineFromVisible(ALineDisplay: Integer): Integer;
begin
  Result := SendEditor(SCI_DOCLINEFROMVISIBLE, ALineDisplay, 0);
end;

function TDScintilla.WrapCount(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_WRAPCOUNT, ALine, 0);
end;

procedure TDScintilla.ShowLines(ALineStart: Integer; ALineEnd: Integer);
begin
  SendEditor(SCI_SHOWLINES, ALineStart, ALineEnd);
end;

procedure TDScintilla.HideLines(ALineStart: Integer; ALineEnd: Integer);
begin
  SendEditor(SCI_HIDELINES, ALineStart, ALineEnd);
end;

procedure TDScintilla.ToggleFold(ALine: Integer);
begin
  SendEditor(SCI_TOGGLEFOLD, ALine, 0);
end;

procedure TDScintilla.FoldLine(ALine: Integer; AAction: Integer);
begin
  SendEditor(SCI_FOLDLINE, ALine, AAction);
end;

procedure TDScintilla.FoldChildren(ALine: Integer; AAction: Integer);
begin
  SendEditor(SCI_FOLDCHILDREN, ALine, AAction);
end;

procedure TDScintilla.ExpandChildren(ALine: Integer; ALevel: Integer);
begin
  SendEditor(SCI_EXPANDCHILDREN, ALine, ALevel);
end;

procedure TDScintilla.FoldAll(AAction: Integer);
begin
  SendEditor(SCI_FOLDALL, AAction, 0);
end;

procedure TDScintilla.EnsureVisible(ALine: Integer);
begin
  SendEditor(SCI_ENSUREVISIBLE, ALine, 0);
end;

procedure TDScintilla.SetFoldFlags(AFlags: Integer);
begin
  SendEditor(SCI_SETFOLDFLAGS, AFlags, 0);
end;

procedure TDScintilla.EnsureVisibleEnforcePolicy(ALine: Integer);
begin
  SendEditor(SCI_ENSUREVISIBLEENFORCEPOLICY, ALine, 0);
end;

function TDScintilla.WordStartPosition(APos: Integer; AOnlyWordCharacters: Boolean): Integer;
begin
  Result := SendEditor(SCI_WORDSTARTPOSITION, APos, Integer(AOnlyWordCharacters));
end;

function TDScintilla.WordEndPosition(APos: Integer; AOnlyWordCharacters: Boolean): Integer;
begin
  Result := SendEditor(SCI_WORDENDPOSITION, APos, Integer(AOnlyWordCharacters));
end;

function TDScintilla.TextWidth(AStyle: Integer; const AText: UnicodeString): Integer;
begin
  Result := FHelper.SetText(SCI_TEXTWIDTH, AStyle, AText);
end;

function TDScintilla.TextHeight(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_TEXTHEIGHT, ALine, 0);
end;

procedure TDScintilla.AppendText(const AText: UnicodeString);
begin
  FHelper.SetTextLen(SCI_APPENDTEXT, AText);
end;

function TDScintilla.GetTag(ATagNumber: Integer): UnicodeString;
begin
  FHelper.GetText(SCI_GETTAG, ATagNumber, Result);
end;

procedure TDScintilla.TargetFromSelection;
begin
  SendEditor(SCI_TARGETFROMSELECTION, 0, 0);
end;

procedure TDScintilla.LinesJoin;
begin
  SendEditor(SCI_LINESJOIN, 0, 0);
end;

procedure TDScintilla.LinesSplit(APixelWidth: Integer);
begin
  SendEditor(SCI_LINESSPLIT, APixelWidth, 0);
end;

procedure TDScintilla.SetFoldMarginColour(AUseSetting: Boolean; ABack: TColor);
begin
  SendEditor(SCI_SETFOLDMARGINCOLOUR, Integer(AUseSetting), Integer(ABack));
end;

procedure TDScintilla.SetFoldMarginHiColour(AUseSetting: Boolean; AFore: TColor);
begin
  SendEditor(SCI_SETFOLDMARGINHICOLOUR, Integer(AUseSetting), Integer(AFore));
end;

procedure TDScintilla.LineDown;
begin
  SendEditor(SCI_LINEDOWN, 0, 0);
end;

procedure TDScintilla.LineDownExtend;
begin
  SendEditor(SCI_LINEDOWNEXTEND, 0, 0);
end;

procedure TDScintilla.LineUp;
begin
  SendEditor(SCI_LINEUP, 0, 0);
end;

procedure TDScintilla.LineUpExtend;
begin
  SendEditor(SCI_LINEUPEXTEND, 0, 0);
end;

procedure TDScintilla.CharLeft;
begin
  SendEditor(SCI_CHARLEFT, 0, 0);
end;

procedure TDScintilla.CharLeftExtend;
begin
  SendEditor(SCI_CHARLEFTEXTEND, 0, 0);
end;

procedure TDScintilla.CharRight;
begin
  SendEditor(SCI_CHARRIGHT, 0, 0);
end;

procedure TDScintilla.CharRightExtend;
begin
  SendEditor(SCI_CHARRIGHTEXTEND, 0, 0);
end;

procedure TDScintilla.WordLeft;
begin
  SendEditor(SCI_WORDLEFT, 0, 0);
end;

procedure TDScintilla.WordLeftExtend;
begin
  SendEditor(SCI_WORDLEFTEXTEND, 0, 0);
end;

procedure TDScintilla.WordRight;
begin
  SendEditor(SCI_WORDRIGHT, 0, 0);
end;

procedure TDScintilla.WordRightExtend;
begin
  SendEditor(SCI_WORDRIGHTEXTEND, 0, 0);
end;

procedure TDScintilla.Home;
begin
  SendEditor(SCI_HOME, 0, 0);
end;

procedure TDScintilla.HomeExtend;
begin
  SendEditor(SCI_HOMEEXTEND, 0, 0);
end;

procedure TDScintilla.LineEnd;
begin
  SendEditor(SCI_LINEEND, 0, 0);
end;

procedure TDScintilla.LineEndExtend;
begin
  SendEditor(SCI_LINEENDEXTEND, 0, 0);
end;

procedure TDScintilla.DocumentStart;
begin
  SendEditor(SCI_DOCUMENTSTART, 0, 0);
end;

procedure TDScintilla.DocumentStartExtend;
begin
  SendEditor(SCI_DOCUMENTSTARTEXTEND, 0, 0);
end;

procedure TDScintilla.DocumentEnd;
begin
  SendEditor(SCI_DOCUMENTEND, 0, 0);
end;

procedure TDScintilla.DocumentEndExtend;
begin
  SendEditor(SCI_DOCUMENTENDEXTEND, 0, 0);
end;

procedure TDScintilla.PageUp;
begin
  SendEditor(SCI_PAGEUP, 0, 0);
end;

procedure TDScintilla.PageUpExtend;
begin
  SendEditor(SCI_PAGEUPEXTEND, 0, 0);
end;

procedure TDScintilla.PageDown;
begin
  SendEditor(SCI_PAGEDOWN, 0, 0);
end;

procedure TDScintilla.PageDownExtend;
begin
  SendEditor(SCI_PAGEDOWNEXTEND, 0, 0);
end;

procedure TDScintilla.EditToggleOvertype;
begin
  SendEditor(SCI_EDITTOGGLEOVERTYPE, 0, 0);
end;

procedure TDScintilla.Cancel;
begin
  SendEditor(SCI_CANCEL, 0, 0);
end;

procedure TDScintilla.DeleteBack;
begin
  SendEditor(SCI_DELETEBACK, 0, 0);
end;

procedure TDScintilla.Tab;
begin
  SendEditor(SCI_TAB, 0, 0);
end;

procedure TDScintilla.BackTab;
begin
  SendEditor(SCI_BACKTAB, 0, 0);
end;

procedure TDScintilla.NewLine;
begin
  SendEditor(SCI_NEWLINE, 0, 0);
end;

procedure TDScintilla.FormFeed;
begin
  SendEditor(SCI_FORMFEED, 0, 0);
end;

procedure TDScintilla.VCHome;
begin
  SendEditor(SCI_VCHOME, 0, 0);
end;

procedure TDScintilla.VCHomeExtend;
begin
  SendEditor(SCI_VCHOMEEXTEND, 0, 0);
end;

procedure TDScintilla.ZoomIn;
begin
  SendEditor(SCI_ZOOMIN, 0, 0);
end;

procedure TDScintilla.ZoomOut;
begin
  SendEditor(SCI_ZOOMOUT, 0, 0);
end;

procedure TDScintilla.DelWordLeft;
begin
  SendEditor(SCI_DELWORDLEFT, 0, 0);
end;

procedure TDScintilla.DelWordRight;
begin
  SendEditor(SCI_DELWORDRIGHT, 0, 0);
end;

procedure TDScintilla.DelWordRightEnd;
begin
  SendEditor(SCI_DELWORDRIGHTEND, 0, 0);
end;

procedure TDScintilla.LineCut;
begin
  SendEditor(SCI_LINECUT, 0, 0);
end;

procedure TDScintilla.LineDelete;
begin
  SendEditor(SCI_LINEDELETE, 0, 0);
end;

procedure TDScintilla.LineTranspose;
begin
  SendEditor(SCI_LINETRANSPOSE, 0, 0);
end;

procedure TDScintilla.LineDuplicate;
begin
  SendEditor(SCI_LINEDUPLICATE, 0, 0);
end;

procedure TDScintilla.LowerCase;
begin
  SendEditor(SCI_LOWERCASE, 0, 0);
end;

procedure TDScintilla.UpperCase;
begin
  SendEditor(SCI_UPPERCASE, 0, 0);
end;

procedure TDScintilla.LineScrollDown;
begin
  SendEditor(SCI_LINESCROLLDOWN, 0, 0);
end;

procedure TDScintilla.LineScrollUp;
begin
  SendEditor(SCI_LINESCROLLUP, 0, 0);
end;

procedure TDScintilla.DeleteBackNotLine;
begin
  SendEditor(SCI_DELETEBACKNOTLINE, 0, 0);
end;

procedure TDScintilla.HomeDisplay;
begin
  SendEditor(SCI_HOMEDISPLAY, 0, 0);
end;

procedure TDScintilla.HomeDisplayExtend;
begin
  SendEditor(SCI_HOMEDISPLAYEXTEND, 0, 0);
end;

procedure TDScintilla.LineEndDisplay;
begin
  SendEditor(SCI_LINEENDDISPLAY, 0, 0);
end;

procedure TDScintilla.LineEndDisplayExtend;
begin
  SendEditor(SCI_LINEENDDISPLAYEXTEND, 0, 0);
end;

procedure TDScintilla.HomeWrap;
begin
  SendEditor(SCI_HOMEWRAP, 0, 0);
end;

procedure TDScintilla.HomeWrapExtend;
begin
  SendEditor(SCI_HOMEWRAPEXTEND, 0, 0);
end;

procedure TDScintilla.LineEndWrap;
begin
  SendEditor(SCI_LINEENDWRAP, 0, 0);
end;

procedure TDScintilla.LineEndWrapExtend;
begin
  SendEditor(SCI_LINEENDWRAPEXTEND, 0, 0);
end;

procedure TDScintilla.VCHomeWrap;
begin
  SendEditor(SCI_VCHOMEWRAP, 0, 0);
end;

procedure TDScintilla.VCHomeWrapExtend;
begin
  SendEditor(SCI_VCHOMEWRAPEXTEND, 0, 0);
end;

procedure TDScintilla.LineCopy;
begin
  SendEditor(SCI_LINECOPY, 0, 0);
end;

procedure TDScintilla.MoveCaretInsideView;
begin
  SendEditor(SCI_MOVECARETINSIDEVIEW, 0, 0);
end;

function TDScintilla.LineLength(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_LINELENGTH, ALine, 0);
end;

procedure TDScintilla.BraceHighlight(APos1: Integer; APos2: Integer);
begin
  SendEditor(SCI_BRACEHIGHLIGHT, APos1, APos2);
end;

procedure TDScintilla.BraceHighlightIndicator(AUseBraceHighlightIndicator: Boolean; AIndicator: Integer);
begin
  SendEditor(SCI_BRACEHIGHLIGHTINDICATOR, Integer(AUseBraceHighlightIndicator), AIndicator);
end;

procedure TDScintilla.BraceBadLight(APos: Integer);
begin
  SendEditor(SCI_BRACEBADLIGHT, APos, 0);
end;

procedure TDScintilla.BraceBadLightIndicator(AUseBraceBadLightIndicator: Boolean; AIndicator: Integer);
begin
  SendEditor(SCI_BRACEBADLIGHTINDICATOR, Integer(AUseBraceBadLightIndicator), AIndicator);
end;

function TDScintilla.BraceMatch(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_BRACEMATCH, APos, 0);
end;

procedure TDScintilla.SearchAnchor;
begin
  SendEditor(SCI_SEARCHANCHOR, 0, 0);
end;

function TDScintilla.SearchNext(AFlags: Integer; const AText: UnicodeString): Integer;
begin
  Result := FHelper.SetText(SCI_SEARCHNEXT, AFlags, AText);
end;

function TDScintilla.SearchPrev(AFlags: Integer; const AText: UnicodeString): Integer;
begin
  Result := FHelper.SetText(SCI_SEARCHPREV, AFlags, AText);
end;

function TDScintilla.LinesOnScreen: Integer;
begin
  Result := SendEditor(SCI_LINESONSCREEN, 0, 0);
end;

procedure TDScintilla.UsePopUp(AAllowPopUp: Boolean);
begin
  SendEditor(SCI_USEPOPUP, Integer(AAllowPopUp), 0);
end;

function TDScintilla.SelectionIsRectangle: Boolean;
begin
  Result := Boolean(SendEditor(SCI_SELECTIONISRECTANGLE, 0, 0));
end;

function TDScintilla.CreateDocument: TDSciDocument;
begin
  Result := TDSciDocument(SendEditor(SCI_CREATEDOCUMENT, 0, 0));
end;

procedure TDScintilla.AddRefDocument(ADoc: TDSciDocument);
begin
  if ADoc <>  nil then
    SendEditor(SCI_ADDREFDOCUMENT, 0, Integer(ADoc));
end;

procedure TDScintilla.ReleaseDocument(ADoc: TDSciDocument);
begin
  if ADoc <> nil then
    SendEditor(SCI_RELEASEDOCUMENT, 0, Integer(ADoc));
end;

procedure TDScintilla.WordPartLeft;
begin
  SendEditor(SCI_WORDPARTLEFT, 0, 0);
end;

procedure TDScintilla.WordPartLeftExtend;
begin
  SendEditor(SCI_WORDPARTLEFTEXTEND, 0, 0);
end;

procedure TDScintilla.WordPartRight;
begin
  SendEditor(SCI_WORDPARTRIGHT, 0, 0);
end;

procedure TDScintilla.WordPartRightExtend;
begin
  SendEditor(SCI_WORDPARTRIGHTEXTEND, 0, 0);
end;

procedure TDScintilla.SetVisiblePolicy(AVisiblePolicy: Integer; AVisibleSlop: Integer);
begin
  SendEditor(SCI_SETVISIBLEPOLICY, AVisiblePolicy, AVisibleSlop);
end;

procedure TDScintilla.DelLineLeft;
begin
  SendEditor(SCI_DELLINELEFT, 0, 0);
end;

procedure TDScintilla.DelLineRight;
begin
  SendEditor(SCI_DELLINERIGHT, 0, 0);
end;

procedure TDScintilla.ChooseCaretX;
begin
  SendEditor(SCI_CHOOSECARETX, 0, 0);
end;

procedure TDScintilla.GrabFocus;
begin
  SendEditor(SCI_GRABFOCUS, 0, 0);
end;

procedure TDScintilla.SetXCaretPolicy(ACaretPolicy: Integer; ACaretSlop: Integer);
begin
  SendEditor(SCI_SETXCARETPOLICY, ACaretPolicy, ACaretSlop);
end;

procedure TDScintilla.SetYCaretPolicy(ACaretPolicy: Integer; ACaretSlop: Integer);
begin
  SendEditor(SCI_SETYCARETPOLICY, ACaretPolicy, ACaretSlop);
end;

procedure TDScintilla.ParaDown;
begin
  SendEditor(SCI_PARADOWN, 0, 0);
end;

procedure TDScintilla.ParaDownExtend;
begin
  SendEditor(SCI_PARADOWNEXTEND, 0, 0);
end;

procedure TDScintilla.ParaUp;
begin
  SendEditor(SCI_PARAUP, 0, 0);
end;

procedure TDScintilla.ParaUpExtend;
begin
  SendEditor(SCI_PARAUPEXTEND, 0, 0);
end;

function TDScintilla.PositionBefore(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_POSITIONBEFORE, APos, 0);
end;

function TDScintilla.PositionAfter(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_POSITIONAFTER, APos, 0);
end;

function TDScintilla.PositionRelative(APos: Integer; ARelative: Integer): Integer;
begin
  Result := SendEditor(SCI_POSITIONRELATIVE, APos, ARelative);
end;

procedure TDScintilla.CopyRange(AStart: Integer; AEnd: Integer);
begin
  SendEditor(SCI_COPYRANGE, AStart, AEnd);
end;

procedure TDScintilla.CopyText(const AText: UnicodeString);
begin
  FHelper.SetTextLen(SCI_COPYTEXT, AText);
end;
function TDScintilla.GetLineSelStartPosition(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLINESELSTARTPOSITION, ALine, 0);
end;

function TDScintilla.GetLineSelEndPosition(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLINESELENDPOSITION, ALine, 0);
end;

procedure TDScintilla.LineDownRectExtend;
begin
  SendEditor(SCI_LINEDOWNRECTEXTEND, 0, 0);
end;

procedure TDScintilla.LineUpRectExtend;
begin
  SendEditor(SCI_LINEUPRECTEXTEND, 0, 0);
end;

procedure TDScintilla.CharLeftRectExtend;
begin
  SendEditor(SCI_CHARLEFTRECTEXTEND, 0, 0);
end;

procedure TDScintilla.CharRightRectExtend;
begin
  SendEditor(SCI_CHARRIGHTRECTEXTEND, 0, 0);
end;

procedure TDScintilla.HomeRectExtend;
begin
  SendEditor(SCI_HOMERECTEXTEND, 0, 0);
end;

procedure TDScintilla.VCHomeRectExtend;
begin
  SendEditor(SCI_VCHOMERECTEXTEND, 0, 0);
end;

procedure TDScintilla.LineEndRectExtend;
begin
  SendEditor(SCI_LINEENDRECTEXTEND, 0, 0);
end;

procedure TDScintilla.PageUpRectExtend;
begin
  SendEditor(SCI_PAGEUPRECTEXTEND, 0, 0);
end;

procedure TDScintilla.PageDownRectExtend;
begin
  SendEditor(SCI_PAGEDOWNRECTEXTEND, 0, 0);
end;

procedure TDScintilla.StutteredPageUp;
begin
  SendEditor(SCI_STUTTEREDPAGEUP, 0, 0);
end;

procedure TDScintilla.StutteredPageUpExtend;
begin
  SendEditor(SCI_STUTTEREDPAGEUPEXTEND, 0, 0);
end;

procedure TDScintilla.StutteredPageDown;
begin
  SendEditor(SCI_STUTTEREDPAGEDOWN, 0, 0);
end;

procedure TDScintilla.StutteredPageDownExtend;
begin
  SendEditor(SCI_STUTTEREDPAGEDOWNEXTEND, 0, 0);
end;

procedure TDScintilla.WordLeftEnd;
begin
  SendEditor(SCI_WORDLEFTEND, 0, 0);
end;

procedure TDScintilla.WordLeftEndExtend;
begin
  SendEditor(SCI_WORDLEFTENDEXTEND, 0, 0);
end;

procedure TDScintilla.WordRightEnd;
begin
  SendEditor(SCI_WORDRIGHTEND, 0, 0);
end;

procedure TDScintilla.WordRightEndExtend;
begin
  SendEditor(SCI_WORDRIGHTENDEXTEND, 0, 0);
end;

procedure TDScintilla.SetCharsDefault;
begin
  SendEditor(SCI_SETCHARSDEFAULT, 0, 0);
end;

function TDScintilla.AutoCGetCurrent: Integer;
begin
  Result := SendEditor(SCI_AUTOCGETCURRENT, 0, 0);
end;

function TDScintilla.AutoCGetCurrentText: UnicodeString;
begin
  FHelper.GetText(SCI_AUTOCGETCURRENTTEXT, 0, Result);
end;

procedure TDScintilla.Allocate(ABytes: Integer);
begin
  SendEditor(SCI_ALLOCATE, ABytes, 0);
end;

// function TDScintilla.TargetAsUTF8(AS: PAnsiChar): Integer;
// begin
//   Result := SendEditor(SCI_TARGETASUTF8, 0, Integer(AS));
// end;

// procedure TDScintilla.SetLengthForEncode(ABytes: Integer);
// begin
//   SendEditor(SCI_SETLENGTHFORENCODE, ABytes, 0);
// end;

// function TDScintilla.EncodedFromUTF8(AUtf8: PAnsiChar; AEncoded: PAnsiChar): Integer;
// begin
//   Result := SendEditor(SCI_ENCODEDFROMUTF8, Integer(AUtf8), Integer(AEncoded));
// end;

function TDScintilla.FindColumn(ALine: Integer; AColumn: Integer): Integer;
begin
  Result := SendEditor(SCI_FINDCOLUMN, ALine, AColumn);
end;

procedure TDScintilla.ToggleCaretSticky;
begin
  SendEditor(SCI_TOGGLECARETSTICKY, 0, 0);
end;

procedure TDScintilla.SelectionDuplicate;
begin
  SendEditor(SCI_SELECTIONDUPLICATE, 0, 0);
end;

procedure TDScintilla.IndicatorFillRange(APosition: Integer; AFillLength: Integer);
begin
  SendEditor(SCI_INDICATORFILLRANGE, APosition, AFillLength);
end;

procedure TDScintilla.IndicatorClearRange(APosition: Integer; AClearLength: Integer);
begin
  SendEditor(SCI_INDICATORCLEARRANGE, APosition, AClearLength);
end;

function TDScintilla.IndicatorAllOnFor(APosition: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICATORALLONFOR, APosition, 0);
end;

function TDScintilla.IndicatorValueAt(AIndicator: Integer; APosition: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICATORVALUEAT, AIndicator, APosition);
end;

function TDScintilla.IndicatorStart(AIndicator: Integer; APosition: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICATORSTART, AIndicator, APosition);
end;

function TDScintilla.IndicatorEnd(AIndicator: Integer; APosition: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICATOREND, AIndicator, APosition);
end;

procedure TDScintilla.CopyAllowLine;
begin
  SendEditor(SCI_COPYALLOWLINE, 0, 0);
end;

function TDScintilla.GetGapPosition: Integer;
begin
  Result := SendEditor(SCI_GETGAPPOSITION, 0, 0);
end;

function TDScintilla.MarkerSymbolDefined(AMarkerNumber: Integer): Integer;
begin
  Result := SendEditor(SCI_MARKERSYMBOLDEFINED, AMarkerNumber, 0);
end;

procedure TDScintilla.MarginTextClearAll;
begin
  SendEditor(SCI_MARGINTEXTCLEARALL, 0, 0);
end;

procedure TDScintilla.AnnotationClearAll;
begin
  SendEditor(SCI_ANNOTATIONCLEARALL, 0, 0);
end;

procedure TDScintilla.ReleaseAllExtendedStyles;
begin
  SendEditor(SCI_RELEASEALLEXTENDEDSTYLES, 0, 0);
end;

function TDScintilla.AllocateExtendedStyles(ANumberStyles: Integer): Integer;
begin
  Result := SendEditor(SCI_ALLOCATEEXTENDEDSTYLES, ANumberStyles, 0);
end;

procedure TDScintilla.AddUndoAction(AToken: Integer; AFlags: Integer);
begin
  SendEditor(SCI_ADDUNDOACTION, AToken, AFlags);
end;

function TDScintilla.CharPositionFromPoint(AX: Integer; AY: Integer): Integer;
begin
  Result := SendEditor(SCI_CHARPOSITIONFROMPOINT, AX, AY);
end;

function TDScintilla.CharPositionFromPointClose(AX: Integer; AY: Integer): Integer;
begin
  Result := SendEditor(SCI_CHARPOSITIONFROMPOINTCLOSE, AX, AY);
end;

procedure TDScintilla.ClearSelections;
begin
  SendEditor(SCI_CLEARSELECTIONS, 0, 0);
end;

function TDScintilla.SetSelection(ACaret: Integer; AAnchor: Integer): Integer;
begin
  Result := SendEditor(SCI_SETSELECTION, ACaret, AAnchor);
end;

function TDScintilla.AddSelection(ACaret: Integer; AAnchor: Integer): Integer;
begin
  Result := SendEditor(SCI_ADDSELECTION, ACaret, AAnchor);
end;

procedure TDScintilla.DropSelectionN(ASelection: Integer);
begin
  SendEditor(SCI_DROPSELECTIONN, ASelection, 0);
end;

procedure TDScintilla.RotateSelection;
begin
  SendEditor(SCI_ROTATESELECTION, 0, 0);
end;

procedure TDScintilla.SwapMainAnchorCaret;
begin
  SendEditor(SCI_SWAPMAINANCHORCARET, 0, 0);
end;

function TDScintilla.ChangeLexerState(AStart: Integer; AEnd: Integer): Integer;
begin
  Result := SendEditor(SCI_CHANGELEXERSTATE, AStart, AEnd);
end;

function TDScintilla.ContractedFoldNext(ALineStart: Integer): Integer;
begin
  Result := SendEditor(SCI_CONTRACTEDFOLDNEXT, ALineStart, 0);
end;

procedure TDScintilla.VerticalCentreCaret;
begin
  SendEditor(SCI_VERTICALCENTRECARET, 0, 0);
end;

procedure TDScintilla.MoveSelectedLinesUp;
begin
  SendEditor(SCI_MOVESELECTEDLINESUP, 0, 0);
end;

procedure TDScintilla.MoveSelectedLinesDown;
begin
  SendEditor(SCI_MOVESELECTEDLINESDOWN, 0, 0);
end;

procedure TDScintilla.RGBAImageSetScale(AScalePercent: Integer);
begin
  SendEditor(SCI_RGBAIMAGESETSCALE, AScalePercent, 0);
end;

procedure TDScintilla.MarkerDefineRGBAImage(AMarkerNumber: Integer; APixels: PAnsiChar);
begin
  SendEditor(SCI_MARKERDEFINERGBAIMAGE, AMarkerNumber, Integer(APixels));
end;

procedure TDScintilla.RegisterRGBAImage(AType: Integer; APixels: PAnsiChar);
begin
  SendEditor(SCI_REGISTERRGBAIMAGE, AType, Integer(APixels));
end;

procedure TDScintilla.ScrollToStart;
begin
  SendEditor(SCI_SCROLLTOSTART, 0, 0);
end;

procedure TDScintilla.ScrollToEnd;
begin
  SendEditor(SCI_SCROLLTOEND, 0, 0);
end;

function TDScintilla.CreateLoader(ABytes: Integer): Pointer;
begin
  Result := Pointer(SendEditor(SCI_CREATELOADER, ABytes, 0));
end;

// procedure TDScintilla.FindIndicatorShow(AStart: Integer; AEnd: Integer);
// begin
//   SendEditor(SCI_FINDINDICATORSHOW, AStart, AEnd);
// end;

// procedure TDScintilla.FindIndicatorFlash(AStart: Integer; AEnd: Integer);
// begin
//   SendEditor(SCI_FINDINDICATORFLASH, AStart, AEnd);
// end;

// procedure TDScintilla.FindIndicatorHide;
// begin
//   SendEditor(SCI_FINDINDICATORHIDE, 0, 0);
// end;

procedure TDScintilla.VCHomeDisplay;
begin
  SendEditor(SCI_VCHOMEDISPLAY, 0, 0);
end;

procedure TDScintilla.VCHomeDisplayExtend;
begin
  SendEditor(SCI_VCHOMEDISPLAYEXTEND, 0, 0);
end;

procedure TDScintilla.ClearRepresentation(AEncodedCharacter: AnsiString);
begin
  SendEditor(SCI_CLEARREPRESENTATION, Integer(FHelper.GetPtrFromAStr(AEncodedCharacter)), 0);
end;

procedure TDScintilla.StartRecord;
begin
  SendEditor(SCI_STARTRECORD, 0, 0);
end;

procedure TDScintilla.StopRecord;
begin
  SendEditor(SCI_STOPRECORD, 0, 0);
end;

procedure TDScintilla.Colourise(AStart: Integer; AEnd: Integer);
begin
  SendEditor(SCI_COLOURISE, AStart, AEnd);
end;

procedure TDScintilla.SetKeyWords(AKeywordSet: Integer; const AKeyWords: UnicodeString);
begin
  FHelper.SetText(SCI_SETKEYWORDS, AKeywordSet, AKeyWords);
end;

procedure TDScintilla.SetLexerLanguage(const ALanguage: UnicodeString);
begin
  SendEditor(SCI_SETLEXERLANGUAGE, 0, NativeInt(AnsiString(ALanguage)));
end;

procedure TDScintilla.LoadLexerLibrary(const APath: UnicodeString);
begin
  SendEditor(SCI_LOADLEXERLIBRARY, 0, NativeInt(AnsiString(APath)));
end;

function TDScintilla.GetProperty(const AKey: UnicodeString): UnicodeString;
begin
  if AKey = '' then
    Result := ''
  else
    FHelper.GetText(SCI_GETPROPERTY, NativeInt(AnsiString(AKey)), Result);
end;

function TDScintilla.GetPropertyExpanded(const AKey: UnicodeString): UnicodeString;
begin
  if AKey = '' then
    Result := ''
  else
    FHelper.GetText(SCI_GETPROPERTYEXPANDED, NativeInt(AnsiString(AKey)), Result);
end;

function TDScintilla.PrivateLexerCall(AOperation: Integer; APointer: Integer): Integer;
begin
  Result := SendEditor(SCI_PRIVATELEXERCALL, AOperation, APointer);
end;

function TDScintilla.PropertyNames: UnicodeString;
begin
  FHelper.GetText(SCI_PROPERTYNAMES, 0, Result);
end;

function TDScintilla.PropertyType(AName: UnicodeString): Integer;
begin
  if AName = '' then
    Result := -1
  else
    Result := SendEditor(SCI_PROPERTYTYPE, NativeInt(UnicodeStringToUTF8(AName)), 0);
end;

function TDScintilla.DescribeProperty(AName: UnicodeString): UnicodeString;
begin
  if AName = '' then
    Result := ''
  else
    FHelper.GetText(SCI_DESCRIBEPROPERTY, NativeInt(UnicodeStringToUTF8(AName)), Result);
end;

function TDScintilla.DescribeKeyWordSets: UnicodeString;
begin
  FHelper.GetText(SCI_DESCRIBEKEYWORDSETS, 0, Result);
end;

function TDScintilla.AllocateSubStyles(AStyleBase: Integer; ANumberStyles: Integer): Integer;
begin
  Result := SendEditor(SCI_ALLOCATESUBSTYLES, AStyleBase, ANumberStyles);
end;

procedure TDScintilla.FreeSubStyles;
begin
  SendEditor(SCI_FREESUBSTYLES, 0, 0);
end;
{$ENDREGION 'Scintilla properties CODE'}
//{$I DScintillaMethodsCode.inc}

// -----------------------------------------------------------------------------
// Scintilla properties --------------------------------------------------------
// -----------------------------------------------------------------------------
{$REGION 'Scintilla properties CODE'}
function TDScintilla.GetLength: Integer;
begin
  Result := SendEditor(SCI_GETLENGTH, 0, 0);
end;

function TDScintilla.GetCharAt(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_GETCHARAT, APos, 0);
end;

function TDScintilla.GetCurrentPos: Integer;
begin
  Result := SendEditor(SCI_GETCURRENTPOS, 0, 0);
end;

function TDScintilla.GetAnchor: Integer;
begin
  Result := SendEditor(SCI_GETANCHOR, 0, 0);
end;

function TDScintilla.GetStyleAt(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_GETSTYLEAT, APos, 0);
end;

procedure TDScintilla.SetUndoCollection(ACollectUndo: Boolean);
begin
  SendEditor(SCI_SETUNDOCOLLECTION, Integer(ACollectUndo), 0);
end;

function TDScintilla.GetUndoCollection: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETUNDOCOLLECTION, 0, 0));
end;

function TDScintilla.GetViewWS: Integer;
begin
  Result := SendEditor(SCI_GETVIEWWS, 0, 0);
end;

procedure TDScintilla.SetViewWS(AViewWS: Integer);
begin
  SendEditor(SCI_SETVIEWWS, AViewWS, 0);
end;

procedure TDScintilla.SetAnchor(APosAnchor: Integer);
begin
  SendEditor(SCI_SETANCHOR, APosAnchor, 0);
end;

function TDScintilla.GetEndStyled: Integer;
begin
  Result := SendEditor(SCI_GETENDSTYLED, 0, 0);
end;

function TDScintilla.GetEOLMode: Integer;
begin
  Result := SendEditor(SCI_GETEOLMODE, 0, 0);
end;

procedure TDScintilla.SetEOLMode(AEolMode: Integer);
begin
  SendEditor(SCI_SETEOLMODE, AEolMode, 0);
end;

function TDScintilla.GetBufferedDraw: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETBUFFEREDDRAW, 0, 0));
end;

procedure TDScintilla.SetBufferedDraw(ABuffered: Boolean);
begin
  SendEditor(SCI_SETBUFFEREDDRAW, Integer(ABuffered), 0);
end;

procedure TDScintilla.SetTabWidth(ATabWidth: Integer);
begin
  SendEditor(SCI_SETTABWIDTH, ATabWidth, 0);
end;

function TDScintilla.GetTabWidth: Integer;
begin
  Result := SendEditor(SCI_GETTABWIDTH, 0, 0);
end;

procedure TDScintilla.SetCodePage(ACodePage: Integer);
begin
  SendEditor(SCI_SETCODEPAGE, ACodePage, 0);
end;

procedure TDScintilla.SetMarginTypeN(AMargin: Integer; AMarginType: Integer);
begin
  SendEditor(SCI_SETMARGINTYPEN, AMargin, AMarginType);
end;

function TDScintilla.GetMarginTypeN(AMargin: Integer): Integer;
begin
  Result := SendEditor(SCI_GETMARGINTYPEN, AMargin, 0);
end;

procedure TDScintilla.SetMarginWidthN(AMargin: Integer; APixelWidth: Integer);
begin
  SendEditor(SCI_SETMARGINWIDTHN, AMargin, APixelWidth);
end;

function TDScintilla.GetMarginWidthN(AMargin: Integer): Integer;
begin
  Result := SendEditor(SCI_GETMARGINWIDTHN, AMargin, 0);
end;

procedure TDScintilla.SetMarginMaskN(AMargin: Integer; AMask: Integer);
begin
  SendEditor(SCI_SETMARGINMASKN, AMargin, AMask);
end;

function TDScintilla.GetMarginMaskN(AMargin: Integer): Integer;
begin
  Result := SendEditor(SCI_GETMARGINMASKN, AMargin, 0);
end;

procedure TDScintilla.SetMarginSensitiveN(AMargin: Integer; ASensitive: Boolean);
begin
  SendEditor(SCI_SETMARGINSENSITIVEN, AMargin, Integer(ASensitive));
end;

function TDScintilla.GetMarginSensitiveN(AMargin: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETMARGINSENSITIVEN, AMargin, 0));
end;

procedure TDScintilla.SetMarginCursorN(AMargin: Integer; ACursor: Integer);
begin
  SendEditor(SCI_SETMARGINCURSORN, AMargin, ACursor);
end;

function TDScintilla.GetMarginCursorN(AMargin: Integer): Integer;
begin
  Result := SendEditor(SCI_GETMARGINCURSORN, AMargin, 0);
end;

procedure TDScintilla.StyleSetFore(AStyle: Integer; AFore: TColor);
begin
  SendEditor(SCI_STYLESETFORE, AStyle, Integer(AFore));
end;

procedure TDScintilla.StyleSetBack(AStyle: Integer; ABack: TColor);
begin
  SendEditor(SCI_STYLESETBACK, AStyle, Integer(ABack));
end;

procedure TDScintilla.StyleSetBold(AStyle: Integer; ABold: Boolean);
begin
  SendEditor(SCI_STYLESETBOLD, AStyle, Integer(ABold));
end;

procedure TDScintilla.StyleSetItalic(AStyle: Integer; AItalic: Boolean);
begin
  SendEditor(SCI_STYLESETITALIC, AStyle, Integer(AItalic));
end;

procedure TDScintilla.StyleSetSize(AStyle: Integer; ASizePoints: Integer);
begin
  SendEditor(SCI_STYLESETSIZE, AStyle, ASizePoints);
end;

procedure TDScintilla.StyleSetFont(AStyle: Integer; const AFontName: UnicodeString);
begin
  SendEditor(SCI_STYLESETFONT, AStyle, NativeInt(AnsiString(AFontName)));
end;

procedure TDScintilla.StyleSetEOLFilled(AStyle: Integer; AFilled: Boolean);
begin
  SendEditor(SCI_STYLESETEOLFILLED, AStyle, Integer(AFilled));
end;

procedure TDScintilla.StyleSetUnderline(AStyle: Integer; AUnderline: Boolean);
begin
  SendEditor(SCI_STYLESETUNDERLINE, AStyle, Integer(AUnderline));
end;

function TDScintilla.StyleGetFore(AStyle: Integer): TColor;
begin
  Result := TColor(SendEditor(SCI_STYLEGETFORE, AStyle, 0));
end;

function TDScintilla.StyleGetBack(AStyle: Integer): TColor;
begin
  Result := TColor(SendEditor(SCI_STYLEGETBACK, AStyle, 0));
end;

function TDScintilla.StyleGetBold(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETBOLD, AStyle, 0));
end;

function TDScintilla.StyleGetItalic(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETITALIC, AStyle, 0));
end;

function TDScintilla.StyleGetSize(AStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_STYLEGETSIZE, AStyle, 0);
end;

function TDScintilla.StyleGetEOLFilled(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETEOLFILLED, AStyle, 0));
end;

function TDScintilla.StyleGetUnderline(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETUNDERLINE, AStyle, 0));
end;

function TDScintilla.StyleGetCase(AStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_STYLEGETCASE, AStyle, 0);
end;

function TDScintilla.StyleGetCharacterSet(AStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_STYLEGETCHARACTERSET, AStyle, 0);
end;

function TDScintilla.StyleGetVisible(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETVISIBLE, AStyle, 0));
end;

function TDScintilla.StyleGetChangeable(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETCHANGEABLE, AStyle, 0));
end;

function TDScintilla.StyleGetHotSpot(AStyle: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_STYLEGETHOTSPOT, AStyle, 0));
end;

procedure TDScintilla.StyleSetCase(AStyle: Integer; ACaseForce: Integer);
begin
  SendEditor(SCI_STYLESETCASE, AStyle, ACaseForce);
end;

procedure TDScintilla.StyleSetSizeFractional(AStyle: Integer; ACaseForce: Integer);
begin
  SendEditor(SCI_STYLESETSIZEFRACTIONAL, AStyle, ACaseForce);
end;

function TDScintilla.StyleGetSizeFractional(AStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_STYLEGETSIZEFRACTIONAL, AStyle, 0);
end;

procedure TDScintilla.StyleSetWeight(AStyle: Integer; AWeight: Integer);
begin
  SendEditor(SCI_STYLESETWEIGHT, AStyle, AWeight);
end;

function TDScintilla.StyleGetWeight(AStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_STYLEGETWEIGHT, AStyle, 0);
end;

procedure TDScintilla.StyleSetCharacterSet(AStyle: Integer; ACharacterSet: Integer);
begin
  SendEditor(SCI_STYLESETCHARACTERSET, AStyle, ACharacterSet);
end;

procedure TDScintilla.StyleSetHotSpot(AStyle: Integer; AHotspot: Boolean);
begin
  SendEditor(SCI_STYLESETHOTSPOT, AStyle, Integer(AHotspot));
end;

function TDScintilla.GetSelAlpha: Integer;
begin
  Result := SendEditor(SCI_GETSELALPHA, 0, 0);
end;

procedure TDScintilla.SetSelAlpha(AAlpha: Integer);
begin
  SendEditor(SCI_SETSELALPHA, AAlpha, 0);
end;

function TDScintilla.GetSelEOLFilled: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETSELEOLFILLED, 0, 0));
end;

procedure TDScintilla.SetSelEOLFilled(AFilled: Boolean);
begin
  SendEditor(SCI_SETSELEOLFILLED, Integer(AFilled), 0);
end;

procedure TDScintilla.SetCaretFore(AFore: TColor);
begin
  SendEditor(SCI_SETCARETFORE, Integer(AFore), 0);
end;

procedure TDScintilla.StyleSetVisible(AStyle: Integer; AVisible: Boolean);
begin
  SendEditor(SCI_STYLESETVISIBLE, AStyle, Integer(AVisible));
end;

function TDScintilla.GetCaretPeriod: Integer;
begin
  Result := SendEditor(SCI_GETCARETPERIOD, 0, 0);
end;

procedure TDScintilla.SetCaretPeriod(APeriodMilliseconds: Integer);
begin
  SendEditor(SCI_SETCARETPERIOD, APeriodMilliseconds, 0);
end;

procedure TDScintilla.SetWordChars(const ACharacters: AnsiString);
begin
  FHelper.SetTextA(SCI_SETWORDCHARS, 0, ACharacters);
end;

function TDScintilla.GetWordChars: AnsiString;
begin
  FHelper.GetTextA(SCI_GETWORDCHARS, 0, Result);
end;

procedure TDScintilla.IndicSetStyle(AIndic: Integer; AStyle: Integer);
begin
  SendEditor(SCI_INDICSETSTYLE, AIndic, AStyle);
end;

function TDScintilla.IndicGetStyle(AIndic: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICGETSTYLE, AIndic, 0);
end;

procedure TDScintilla.IndicSetFore(AIndic: Integer; AFore: TColor);
begin
  SendEditor(SCI_INDICSETFORE, AIndic, Integer(AFore));
end;

function TDScintilla.IndicGetFore(AIndic: Integer): TColor;
begin
  Result := TColor(SendEditor(SCI_INDICGETFORE, AIndic, 0));
end;

procedure TDScintilla.IndicSetUnder(AIndic: Integer; AUnder: Boolean);
begin
  SendEditor(SCI_INDICSETUNDER, AIndic, Integer(AUnder));
end;

function TDScintilla.IndicGetUnder(AIndic: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_INDICGETUNDER, AIndic, 0));
end;

procedure TDScintilla.SetWhitespaceSize(ASize: Integer);
begin
  SendEditor(SCI_SETWHITESPACESIZE, ASize, 0);
end;

function TDScintilla.GetWhitespaceSize: Integer;
begin
  Result := SendEditor(SCI_GETWHITESPACESIZE, 0, 0);
end;

procedure TDScintilla.SetStyleBits(ABits: Integer);
begin
  SendEditor(SCI_SETSTYLEBITS, ABits, 0);
end;

function TDScintilla.GetStyleBits: Integer;
begin
  Result := SendEditor(SCI_GETSTYLEBITS, 0, 0);
end;

procedure TDScintilla.SetLineState(ALine: Integer; AState: Integer);
begin
  SendEditor(SCI_SETLINESTATE, ALine, AState);
end;

function TDScintilla.GetLineState(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLINESTATE, ALine, 0);
end;

function TDScintilla.GetMaxLineState: Integer;
begin
  Result := SendEditor(SCI_GETMAXLINESTATE, 0, 0);
end;

function TDScintilla.GetCaretLineVisible: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETCARETLINEVISIBLE, 0, 0));
end;

procedure TDScintilla.SetCaretLineVisible(AShow: Boolean);
begin
  SendEditor(SCI_SETCARETLINEVISIBLE, Integer(AShow), 0);
end;

function TDScintilla.GetCaretLineBack: TColor;
begin
  Result := TColor(SendEditor(SCI_GETCARETLINEBACK, 0, 0));
end;

procedure TDScintilla.SetCaretLineBack(ABack: TColor);
begin
  SendEditor(SCI_SETCARETLINEBACK, Integer(ABack), 0);
end;

procedure TDScintilla.StyleSetChangeable(AStyle: Integer; AChangeable: Boolean);
begin
  SendEditor(SCI_STYLESETCHANGEABLE, AStyle, Integer(AChangeable));
end;

procedure TDScintilla.AutoCSetSeparator(ASeparatorCharacter: AnsiChar);
begin
  SendEditor(SCI_AUTOCSETSEPARATOR, Integer(ASeparatorCharacter), 0);
end;

function TDScintilla.AutoCGetSeparator: AnsiChar;
begin
  Result := AnsiChar(SendEditor(SCI_AUTOCGETSEPARATOR, 0, 0));
end;

procedure TDScintilla.AutoCSetCancelAtStart(ACancel: Boolean);
begin
  SendEditor(SCI_AUTOCSETCANCELATSTART, Integer(ACancel), 0);
end;

function TDScintilla.AutoCGetCancelAtStart: Boolean;
begin
  Result := Boolean(SendEditor(SCI_AUTOCGETCANCELATSTART, 0, 0));
end;

procedure TDScintilla.AutoCSetFillUps(const ACharacterSet: UnicodeString);
begin
  FHelper.SetText(SCI_AUTOCSETFILLUPS, 0, ACharacterSet);
end;

procedure TDScintilla.AutoCSetChooseSingle(AChooseSingle: Boolean);
begin
  SendEditor(SCI_AUTOCSETCHOOSESINGLE, Integer(AChooseSingle), 0);
end;

function TDScintilla.AutoCGetChooseSingle: Boolean;
begin
  Result := Boolean(SendEditor(SCI_AUTOCGETCHOOSESINGLE, 0, 0));
end;

procedure TDScintilla.AutoCSetIgnoreCase(AIgnoreCase: Boolean);
begin
  SendEditor(SCI_AUTOCSETIGNORECASE, Integer(AIgnoreCase), 0);
end;

function TDScintilla.AutoCGetIgnoreCase: Boolean;
begin
  Result := Boolean(SendEditor(SCI_AUTOCGETIGNORECASE, 0, 0));
end;

procedure TDScintilla.AutoCSetAutoHide(AAutoHide: Boolean);
begin
  SendEditor(SCI_AUTOCSETAUTOHIDE, Integer(AAutoHide), 0);
end;

function TDScintilla.AutoCGetAutoHide: Boolean;
begin
  Result := Boolean(SendEditor(SCI_AUTOCGETAUTOHIDE, 0, 0));
end;

procedure TDScintilla.AutoCSetDropRestOfWord(ADropRestOfWord: Boolean);
begin
  SendEditor(SCI_AUTOCSETDROPRESTOFWORD, Integer(ADropRestOfWord), 0);
end;

function TDScintilla.AutoCGetDropRestOfWord: Boolean;
begin
  Result := Boolean(SendEditor(SCI_AUTOCGETDROPRESTOFWORD, 0, 0));
end;

function TDScintilla.AutoCGetTypeSeparator: AnsiChar;
begin
  Result := AnsiChar(SendEditor(SCI_AUTOCGETTYPESEPARATOR, 0, 0));
end;

procedure TDScintilla.AutoCSetTypeSeparator(ASeparatorCharacter: AnsiChar);
begin
  SendEditor(SCI_AUTOCSETTYPESEPARATOR, Integer(ASeparatorCharacter), 0);
end;

procedure TDScintilla.AutoCSetMaxWidth(ACharacterCount: Integer);
begin
  SendEditor(SCI_AUTOCSETMAXWIDTH, ACharacterCount, 0);
end;

function TDScintilla.AutoCGetMaxWidth: Integer;
begin
  Result := SendEditor(SCI_AUTOCGETMAXWIDTH, 0, 0);
end;

procedure TDScintilla.AutoCSetMaxHeight(ARowCount: Integer);
begin
  SendEditor(SCI_AUTOCSETMAXHEIGHT, ARowCount, 0);
end;

function TDScintilla.AutoCGetMaxHeight: Integer;
begin
  Result := SendEditor(SCI_AUTOCGETMAXHEIGHT, 0, 0);
end;

procedure TDScintilla.SetIndent(AIndentSize: Integer);
begin
  SendEditor(SCI_SETINDENT, AIndentSize, 0);
end;

function TDScintilla.GetIndent: Integer;
begin
  Result := SendEditor(SCI_GETINDENT, 0, 0);
end;

procedure TDScintilla.SetUseTabs(AUseTabs: Boolean);
begin
  SendEditor(SCI_SETUSETABS, Integer(AUseTabs), 0);
end;

function TDScintilla.GetUseTabs: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETUSETABS, 0, 0));
end;

procedure TDScintilla.SetLineIndentation(ALine: Integer; AIndentSize: Integer);
begin
  SendEditor(SCI_SETLINEINDENTATION, ALine, AIndentSize);
end;

function TDScintilla.GetLineIndentation(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLINEINDENTATION, ALine, 0);
end;

function TDScintilla.GetLineIndentPosition(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLINEINDENTPOSITION, ALine, 0);
end;

function TDScintilla.GetColumn(APos: Integer): Integer;
begin
  Result := SendEditor(SCI_GETCOLUMN, APos, 0);
end;

procedure TDScintilla.SetHScrollBar(AShow: Boolean);
begin
  SendEditor(SCI_SETHSCROLLBAR, Integer(AShow), 0);
end;

function TDScintilla.GetHScrollBar: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETHSCROLLBAR, 0, 0));
end;

procedure TDScintilla.SetIndentationGuides(AIndentView: Integer);
begin
  SendEditor(SCI_SETINDENTATIONGUIDES, AIndentView, 0);
end;

function TDScintilla.GetIndentationGuides: Integer;
begin
  Result := SendEditor(SCI_GETINDENTATIONGUIDES, 0, 0);
end;

procedure TDScintilla.SetHighlightGuide(AColumn: Integer);
begin
  SendEditor(SCI_SETHIGHLIGHTGUIDE, AColumn, 0);
end;

function TDScintilla.GetHighlightGuide: Integer;
begin
  Result := SendEditor(SCI_GETHIGHLIGHTGUIDE, 0, 0);
end;

function TDScintilla.GetLineEndPosition(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLINEENDPOSITION, ALine, 0);
end;

function TDScintilla.GetCodePage: Integer;
begin
  Result := SendEditor(SCI_GETCODEPAGE, 0, 0);
end;

function TDScintilla.GetCaretFore: TColor;
begin
  Result := TColor(SendEditor(SCI_GETCARETFORE, 0, 0));
end;

function TDScintilla.GetReadOnly: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETREADONLY, 0, 0));
end;

procedure TDScintilla.SetCurrentPos(APos: Integer);
begin
  SendEditor(SCI_SETCURRENTPOS, APos, 0);
end;

procedure TDScintilla.SetSelectionStart(APos: Integer);
begin
  SendEditor(SCI_SETSELECTIONSTART, APos, 0);
end;

function TDScintilla.GetSelectionStart: Integer;
begin
  Result := SendEditor(SCI_GETSELECTIONSTART, 0, 0);
end;

procedure TDScintilla.SetSelectionEnd(APos: Integer);
begin
  SendEditor(SCI_SETSELECTIONEND, APos, 0);
end;

function TDScintilla.GetSelectionEnd: Integer;
begin
  Result := SendEditor(SCI_GETSELECTIONEND, 0, 0);
end;

procedure TDScintilla.SetPrintMagnification(AMagnification: Integer);
begin
  SendEditor(SCI_SETPRINTMAGNIFICATION, AMagnification, 0);
end;

function TDScintilla.GetPrintMagnification: Integer;
begin
  Result := SendEditor(SCI_GETPRINTMAGNIFICATION, 0, 0);
end;

procedure TDScintilla.SetPrintColourMode(AMode: Integer);
begin
  SendEditor(SCI_SETPRINTCOLOURMODE, AMode, 0);
end;

function TDScintilla.GetPrintColourMode: Integer;
begin
  Result := SendEditor(SCI_GETPRINTCOLOURMODE, 0, 0);
end;

function TDScintilla.GetFirstVisibleLine: Integer;
begin
  Result := SendEditor(SCI_GETFIRSTVISIBLELINE, 0, 0);
end;

function TDScintilla.GetLineCount: Integer;
begin
  Result := SendEditor(SCI_GETLINECOUNT, 0, 0);
end;

procedure TDScintilla.SetMarginLeft(APixelWidth: Integer);
begin
  SendEditor(SCI_SETMARGINLEFT, 0, APixelWidth);
end;

function TDScintilla.GetMarginLeft: Integer;
begin
  Result := SendEditor(SCI_GETMARGINLEFT, 0, 0);
end;

procedure TDScintilla.SetMarginRight(APixelWidth: Integer);
begin
  SendEditor(SCI_SETMARGINRIGHT, 0, APixelWidth);
end;

function TDScintilla.GetMarginRight: Integer;
begin
  Result := SendEditor(SCI_GETMARGINRIGHT, 0, 0);
end;

function TDScintilla.GetModify: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETMODIFY, 0, 0));
end;

procedure TDScintilla.SetReadOnly(AReadOnly: Boolean);
begin
  SendEditor(SCI_SETREADONLY, Integer(AReadOnly), 0);
end;

function TDScintilla.GetTextLength: Integer;
begin
  Result := SendEditor(SCI_GETTEXTLENGTH, 0, 0);
end;

function TDScintilla.GetDirectFunction: TDScintillaFunction;
begin
  Result := TDScintillaFunction(SendEditor(SCI_GETDIRECTFUNCTION, 0, 0));
end;

function TDScintilla.GetDirectPointer: Pointer;
begin
  Result := Pointer(SendEditor(SCI_GETDIRECTPOINTER, 0, 0));
end;

procedure TDScintilla.SetOvertype(AOvertype: Boolean);
begin
  SendEditor(SCI_SETOVERTYPE, Integer(AOvertype), 0);
end;

function TDScintilla.GetOvertype: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETOVERTYPE, 0, 0));
end;

procedure TDScintilla.SetCaretWidth(APixelWidth: Integer);
begin
  SendEditor(SCI_SETCARETWIDTH, APixelWidth, 0);
end;

function TDScintilla.GetCaretWidth: Integer;
begin
  Result := SendEditor(SCI_GETCARETWIDTH, 0, 0);
end;

procedure TDScintilla.SetTargetStart(APos: Integer);
begin
  SendEditor(SCI_SETTARGETSTART, APos, 0);
end;

function TDScintilla.GetTargetStart: Integer;
begin
  Result := SendEditor(SCI_GETTARGETSTART, 0, 0);
end;

procedure TDScintilla.SetTargetEnd(APos: Integer);
begin
  SendEditor(SCI_SETTARGETEND, APos, 0);
end;

function TDScintilla.GetTargetEnd: Integer;
begin
  Result := SendEditor(SCI_GETTARGETEND, 0, 0);
end;

procedure TDScintilla.SetSearchFlags(AFlags: Integer);
begin
  SendEditor(SCI_SETSEARCHFLAGS, AFlags, 0);
end;

function TDScintilla.GetSearchFlags: Integer;
begin
  Result := SendEditor(SCI_GETSEARCHFLAGS, 0, 0);
end;

procedure TDScintilla.CallTipSetPosStart(APosStart: Integer);
begin
  SendEditor(SCI_CALLTIPSETPOSSTART, APosStart, 0);
end;

procedure TDScintilla.CallTipSetBack(ABack: TColor);
begin
  SendEditor(SCI_CALLTIPSETBACK, Integer(ABack), 0);
end;

procedure TDScintilla.CallTipSetFore(AFore: TColor);
begin
  SendEditor(SCI_CALLTIPSETFORE, Integer(AFore), 0);
end;

procedure TDScintilla.CallTipSetForeHlt(AFore: TColor);
begin
  SendEditor(SCI_CALLTIPSETFOREHLT, Integer(AFore), 0);
end;

procedure TDScintilla.CallTipUseStyle(ATabSize: Integer);
begin
  SendEditor(SCI_CALLTIPUSESTYLE, ATabSize, 0);
end;

procedure TDScintilla.CallTipSetPosition(AAbove: Boolean);
begin
  SendEditor(SCI_CALLTIPSETPOSITION, Integer(AAbove), 0);
end;

procedure TDScintilla.SetFoldLevel(ALine: Integer; ALevel: Integer);
begin
  SendEditor(SCI_SETFOLDLEVEL, ALine, ALevel);
end;

function TDScintilla.GetFoldLevel(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETFOLDLEVEL, ALine, 0);
end;

function TDScintilla.GetLastChild(ALine: Integer; ALevel: Integer): Integer;
begin
  Result := SendEditor(SCI_GETLASTCHILD, ALine, ALevel);
end;

function TDScintilla.GetFoldParent(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_GETFOLDPARENT, ALine, 0);
end;

function TDScintilla.GetLineVisible(ALine: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETLINEVISIBLE, ALine, 0));
end;

function TDScintilla.GetAllLinesVisible: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETALLLINESVISIBLE, 0, 0));
end;

procedure TDScintilla.SetFoldExpanded(ALine: Integer; AExpanded: Boolean);
begin
  SendEditor(SCI_SETFOLDEXPANDED, ALine, Integer(AExpanded));
end;

function TDScintilla.GetFoldExpanded(ALine: Integer): Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETFOLDEXPANDED, ALine, 0));
end;

procedure TDScintilla.SetAutomaticFold(AAutomaticFold: Integer);
begin
  SendEditor(SCI_SETAUTOMATICFOLD, AAutomaticFold, 0);
end;

function TDScintilla.GetAutomaticFold: Integer;
begin
  Result := SendEditor(SCI_GETAUTOMATICFOLD, 0, 0);
end;

procedure TDScintilla.SetTabIndents(ATabIndents: Boolean);
begin
  SendEditor(SCI_SETTABINDENTS, Integer(ATabIndents), 0);
end;

function TDScintilla.GetTabIndents: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETTABINDENTS, 0, 0));
end;

procedure TDScintilla.SetBackSpaceUnIndents(ABsUnIndents: Boolean);
begin
  SendEditor(SCI_SETBACKSPACEUNINDENTS, Integer(ABsUnIndents), 0);
end;

function TDScintilla.GetBackSpaceUnIndents: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETBACKSPACEUNINDENTS, 0, 0));
end;

procedure TDScintilla.SetMouseDwellTime(APeriodMilliseconds: Integer);
begin
  SendEditor(SCI_SETMOUSEDWELLTIME, APeriodMilliseconds, 0);
end;

function TDScintilla.GetMouseDwellTime: Integer;
begin
  Result := SendEditor(SCI_GETMOUSEDWELLTIME, 0, 0);
end;

procedure TDScintilla.SetWrapMode(AMode: Integer);
begin
  SendEditor(SCI_SETWRAPMODE, AMode, 0);
end;

function TDScintilla.GetWrapMode: Integer;
begin
  Result := SendEditor(SCI_GETWRAPMODE, 0, 0);
end;

procedure TDScintilla.SetWrapVisualFlags(AWrapVisualFlags: Integer);
begin
  SendEditor(SCI_SETWRAPVISUALFLAGS, AWrapVisualFlags, 0);
end;

function TDScintilla.GetWrapVisualFlags: Integer;
begin
  Result := SendEditor(SCI_GETWRAPVISUALFLAGS, 0, 0);
end;

procedure TDScintilla.SetWrapVisualFlagsLocation(AWrapVisualFlagsLocation: Integer);
begin
  SendEditor(SCI_SETWRAPVISUALFLAGSLOCATION, AWrapVisualFlagsLocation, 0);
end;

function TDScintilla.GetWrapVisualFlagsLocation: Integer;
begin
  Result := SendEditor(SCI_GETWRAPVISUALFLAGSLOCATION, 0, 0);
end;

procedure TDScintilla.SetWrapStartIndent(AIndent: Integer);
begin
  SendEditor(SCI_SETWRAPSTARTINDENT, AIndent, 0);
end;

function TDScintilla.GetWrapStartIndent: Integer;
begin
  Result := SendEditor(SCI_GETWRAPSTARTINDENT, 0, 0);
end;

procedure TDScintilla.SetWrapIndentMode(AMode: Integer);
begin
  SendEditor(SCI_SETWRAPINDENTMODE, AMode, 0);
end;

function TDScintilla.GetWrapIndentMode: Integer;
begin
  Result := SendEditor(SCI_GETWRAPINDENTMODE, 0, 0);
end;

procedure TDScintilla.SetLayoutCache(AMode: Integer);
begin
  SendEditor(SCI_SETLAYOUTCACHE, AMode, 0);
end;

function TDScintilla.GetLayoutCache: Integer;
begin
  Result := SendEditor(SCI_GETLAYOUTCACHE, 0, 0);
end;

procedure TDScintilla.SetScrollWidth(APixelWidth: Integer);
begin
  SendEditor(SCI_SETSCROLLWIDTH, APixelWidth, 0);
end;

function TDScintilla.GetScrollWidth: Integer;
begin
  Result := SendEditor(SCI_GETSCROLLWIDTH, 0, 0);
end;

procedure TDScintilla.SetScrollWidthTracking(ATracking: Boolean);
begin
  SendEditor(SCI_SETSCROLLWIDTHTRACKING, Integer(ATracking), 0);
end;

function TDScintilla.GetScrollWidthTracking: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETSCROLLWIDTHTRACKING, 0, 0));
end;

procedure TDScintilla.SetEndAtLastLine(AEndAtLastLine: Boolean);
begin
  SendEditor(SCI_SETENDATLASTLINE, Integer(AEndAtLastLine), 0);
end;

function TDScintilla.GetEndAtLastLine: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETENDATLASTLINE, 0, 0));
end;

procedure TDScintilla.SetVScrollBar(AShow: Boolean);
begin
  SendEditor(SCI_SETVSCROLLBAR, Integer(AShow), 0);
end;

function TDScintilla.GetVScrollBar: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETVSCROLLBAR, 0, 0));
end;

function TDScintilla.GetTwoPhaseDraw: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETTWOPHASEDRAW, 0, 0));
end;

procedure TDScintilla.SetTwoPhaseDraw(ATwoPhase: Boolean);
begin
  SendEditor(SCI_SETTWOPHASEDRAW, Integer(ATwoPhase), 0);
end;

procedure TDScintilla.SetFontQuality(AFontQuality: Integer);
begin
  SendEditor(SCI_SETFONTQUALITY, AFontQuality, 0);
end;

function TDScintilla.GetFontQuality: Integer;
begin
  Result := SendEditor(SCI_GETFONTQUALITY, 0, 0);
end;

procedure TDScintilla.SetFirstVisibleLine(ALineDisplay: Integer);
begin
  SendEditor(SCI_SETFIRSTVISIBLELINE, ALineDisplay, 0);
end;

procedure TDScintilla.SetMultiPaste(AMultiPaste: Integer);
begin
  SendEditor(SCI_SETMULTIPASTE, AMultiPaste, 0);
end;

function TDScintilla.GetMultiPaste: Integer;
begin
  Result := SendEditor(SCI_GETMULTIPASTE, 0, 0);
end;

function TDScintilla.GetViewEOL: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETVIEWEOL, 0, 0));
end;

procedure TDScintilla.SetViewEOL(AVisible: Boolean);
begin
  SendEditor(SCI_SETVIEWEOL, Integer(AVisible), 0);
end;

function TDScintilla.GetDocPointer: TDSciDocument;
begin
  Result := TDSciDocument(SendEditor(SCI_GETDOCPOINTER, 0, 0));
end;

procedure TDScintilla.SetDocPointer(APointer: TDSciDocument);
begin
  if APointer <> nil then
    SendEditor(SCI_SETDOCPOINTER, 0, Integer(APointer));
end;

procedure TDScintilla.SetModEventMask(AMask: Integer);
begin
  SendEditor(SCI_SETMODEVENTMASK, AMask, 0);
end;

function TDScintilla.GetEdgeColumn: Integer;
begin
  Result := SendEditor(SCI_GETEDGECOLUMN, 0, 0);
end;

procedure TDScintilla.SetEdgeColumn(AColumn: Integer);
begin
  SendEditor(SCI_SETEDGECOLUMN, AColumn, 0);
end;

function TDScintilla.GetEdgeMode: Integer;
begin
  Result := SendEditor(SCI_GETEDGEMODE, 0, 0);
end;

procedure TDScintilla.SetEdgeMode(AMode: Integer);
begin
  SendEditor(SCI_SETEDGEMODE, AMode, 0);
end;

function TDScintilla.GetEdgeColour: TColor;
begin
  Result := TColor(SendEditor(SCI_GETEDGECOLOUR, 0, 0));
end;

procedure TDScintilla.SetEdgeColour(AEdgeColour: TColor);
begin
  SendEditor(SCI_SETEDGECOLOUR, Integer(AEdgeColour), 0);
end;

procedure TDScintilla.SetZoom(AZoom: Integer);
begin
  SendEditor(SCI_SETZOOM, AZoom, 0);
end;

function TDScintilla.GetZoom: Integer;
begin
  Result := SendEditor(SCI_GETZOOM, 0, 0);
end;

function TDScintilla.GetModEventMask: Integer;
begin
  Result := SendEditor(SCI_GETMODEVENTMASK, 0, 0);
end;

procedure TDScintilla.SetFocus(AFocus: Boolean);
begin
  SendEditor(SCI_SETFOCUS, Integer(AFocus), 0);
end;

function TDScintilla.GetFocus: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETFOCUS, 0, 0));
end;

procedure TDScintilla.SetStatus(AStatusCode: Integer);
begin
  SendEditor(SCI_SETSTATUS, AStatusCode, 0);
end;

function TDScintilla.GetStatus: Integer;
begin
  Result := SendEditor(SCI_GETSTATUS, 0, 0);
end;

procedure TDScintilla.SetMouseDownCaptures(ACaptures: Boolean);
begin
  SendEditor(SCI_SETMOUSEDOWNCAPTURES, Integer(ACaptures), 0);
end;

function TDScintilla.GetMouseDownCaptures: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETMOUSEDOWNCAPTURES, 0, 0));
end;

procedure TDScintilla.SetCursor(ACursorType: Integer);
begin
  SendEditor(SCI_SETCURSOR, ACursorType, 0);
end;

function TDScintilla.GetCursor: Integer;
begin
  Result := SendEditor(SCI_GETCURSOR, 0, 0);
end;

procedure TDScintilla.SetControlCharSymbol(ASymbol: Integer);
begin
  SendEditor(SCI_SETCONTROLCHARSYMBOL, ASymbol, 0);
end;

function TDScintilla.GetControlCharSymbol: Integer;
begin
  Result := SendEditor(SCI_GETCONTROLCHARSYMBOL, 0, 0);
end;

procedure TDScintilla.SetXOffset(ANewOffset: Integer);
begin
  SendEditor(SCI_SETXOFFSET, ANewOffset, 0);
end;

function TDScintilla.GetXOffset: Integer;
begin
  Result := SendEditor(SCI_GETXOFFSET, 0, 0);
end;

procedure TDScintilla.SetPrintWrapMode(AMode: Integer);
begin
  SendEditor(SCI_SETPRINTWRAPMODE, AMode, 0);
end;

function TDScintilla.GetPrintWrapMode: Integer;
begin
  Result := SendEditor(SCI_GETPRINTWRAPMODE, 0, 0);
end;

procedure TDScintilla.SetHotspotActiveFore(AUseSetting: Boolean; AFore: TColor);
begin
  SendEditor(SCI_SETHOTSPOTACTIVEFORE, Integer(AUseSetting), Integer(AFore));
end;

function TDScintilla.GetHotspotActiveFore: TColor;
begin
  Result := TColor(SendEditor(SCI_GETHOTSPOTACTIVEFORE, 0, 0));
end;

procedure TDScintilla.SetHotspotActiveBack(AUseSetting: Boolean; ABack: TColor);
begin
  SendEditor(SCI_SETHOTSPOTACTIVEBACK, Integer(AUseSetting), Integer(ABack));
end;

function TDScintilla.GetHotspotActiveBack: TColor;
begin
  Result := TColor(SendEditor(SCI_GETHOTSPOTACTIVEBACK, 0, 0));
end;

procedure TDScintilla.SetHotspotActiveUnderline(AUnderline: Boolean);
begin
  SendEditor(SCI_SETHOTSPOTACTIVEUNDERLINE, Integer(AUnderline), 0);
end;

function TDScintilla.GetHotspotActiveUnderline: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETHOTSPOTACTIVEUNDERLINE, 0, 0));
end;

procedure TDScintilla.SetHotspotSingleLine(ASingleLine: Boolean);
begin
  SendEditor(SCI_SETHOTSPOTSINGLELINE, Integer(ASingleLine), 0);
end;

function TDScintilla.GetHotspotSingleLine: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETHOTSPOTSINGLELINE, 0, 0));
end;

procedure TDScintilla.SetSelectionMode(AMode: Integer);
begin
  SendEditor(SCI_SETSELECTIONMODE, AMode, 0);
end;

function TDScintilla.GetSelectionMode: Integer;
begin
  Result := SendEditor(SCI_GETSELECTIONMODE, 0, 0);
end;

procedure TDScintilla.SetWhitespaceChars(const ACharacters: UnicodeString);
begin
  FHelper.SetText(SCI_SETWHITESPACECHARS, 0, ACharacters);
end;

function TDScintilla.GetWhitespaceChars: AnsiString;
begin
  FHelper.GetTextA(SCI_GETWHITESPACECHARS, 0, Result);
end;

procedure TDScintilla.SetPunctuationChars(const ACharacters: AnsiString);
begin
  FHelper.SetTextA(SCI_SETPUNCTUATIONCHARS, 0, ACharacters);
end;

function TDScintilla.GetPunctuationChars: AnsiString;
begin
  FHelper.GetTextA(SCI_GETPUNCTUATIONCHARS, 0, Result);
end;

procedure TDScintilla.AutoCSetCaseInsensitiveBehaviour(ABehaviour: Integer);
begin
  SendEditor(SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR, ABehaviour, 0);
end;

function TDScintilla.AutoCGetCaseInsensitiveBehaviour: Integer;
begin
  Result := SendEditor(SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR, 0, 0);
end;

procedure TDScintilla.AutoCSetOrder(AOrder: Integer);
begin
  SendEditor(SCI_AUTOCSETORDER, AOrder, 0);
end;

function TDScintilla.AutoCGetOrder: Integer;
begin
  Result := SendEditor(SCI_AUTOCGETORDER, 0, 0);
end;

function TDScintilla.GetCaretSticky: Integer;
begin
  Result := SendEditor(SCI_GETCARETSTICKY, 0, 0);
end;

procedure TDScintilla.SetCaretSticky(AUseCaretStickyBehaviour: Integer);
begin
  SendEditor(SCI_SETCARETSTICKY, AUseCaretStickyBehaviour, 0);
end;

procedure TDScintilla.SetPasteConvertEndings(AConvert: Boolean);
begin
  SendEditor(SCI_SETPASTECONVERTENDINGS, Integer(AConvert), 0);
end;

function TDScintilla.GetPasteConvertEndings: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETPASTECONVERTENDINGS, 0, 0));
end;

procedure TDScintilla.SetCaretLineBackAlpha(AAlpha: Integer);
begin
  SendEditor(SCI_SETCARETLINEBACKALPHA, AAlpha, 0);
end;

function TDScintilla.GetCaretLineBackAlpha: Integer;
begin
  Result := SendEditor(SCI_GETCARETLINEBACKALPHA, 0, 0);
end;

procedure TDScintilla.SetCaretStyle(ACaretStyle: Integer);
begin
  SendEditor(SCI_SETCARETSTYLE, ACaretStyle, 0);
end;

function TDScintilla.GetCaretStyle: Integer;
begin
  Result := SendEditor(SCI_GETCARETSTYLE, 0, 0);
end;

procedure TDScintilla.SetIndicatorCurrent(AIndicator: Integer);
begin
  SendEditor(SCI_SETINDICATORCURRENT, AIndicator, 0);
end;

function TDScintilla.GetIndicatorCurrent: Integer;
begin
  Result := SendEditor(SCI_GETINDICATORCURRENT, 0, 0);
end;

procedure TDScintilla.SetIndicatorValue(AValue: Integer);
begin
  SendEditor(SCI_SETINDICATORVALUE, AValue, 0);
end;

function TDScintilla.GetIndicatorValue: Integer;
begin
  Result := SendEditor(SCI_GETINDICATORVALUE, 0, 0);
end;

procedure TDScintilla.SetPositionCache(ASize: Integer);
begin
  SendEditor(SCI_SETPOSITIONCACHE, ASize, 0);
end;

function TDScintilla.GetPositionCache: Integer;
begin
  Result := SendEditor(SCI_GETPOSITIONCACHE, 0, 0);
end;

function TDScintilla.GetCharacterPointer: PByte;
begin
  Result := PByte(SendEditor(SCI_GETCHARACTERPOINTER, 0, 0));
end;

function TDScintilla.GetRangePointer(APosition: Integer; ARangeLength: Integer): Pointer;
begin
  Result := Pointer(SendEditor(SCI_GETRANGEPOINTER, APosition, ARangeLength));
end;

procedure TDScintilla.SetKeysUnicode(AKeysUnicode: Boolean);
begin
  SendEditor(SCI_SETKEYSUNICODE, Integer(AKeysUnicode), 0);
end;

function TDScintilla.GetKeysUnicode: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETKEYSUNICODE, 0, 0));
end;

procedure TDScintilla.IndicSetAlpha(AIndicator: Integer; AAlpha: Integer);
begin
  SendEditor(SCI_INDICSETALPHA, AIndicator, AAlpha);
end;

function TDScintilla.IndicGetAlpha(AIndicator: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICGETALPHA, AIndicator, 0);
end;

procedure TDScintilla.IndicSetOutlineAlpha(AIndicator: Integer; AAlpha: Integer);
begin
  SendEditor(SCI_INDICSETOUTLINEALPHA, AIndicator, AAlpha);
end;

function TDScintilla.IndicGetOutlineAlpha(AIndicator: Integer): Integer;
begin
  Result := SendEditor(SCI_INDICGETOUTLINEALPHA, AIndicator, 0);
end;

procedure TDScintilla.SetExtraAscent(AExtraAscent: Integer);
begin
  SendEditor(SCI_SETEXTRAASCENT, AExtraAscent, 0);
end;

function TDScintilla.GetExtraAscent: Integer;
begin
  Result := SendEditor(SCI_GETEXTRAASCENT, 0, 0);
end;

procedure TDScintilla.SetExtraDescent(AExtraDescent: Integer);
begin
  SendEditor(SCI_SETEXTRADESCENT, AExtraDescent, 0);
end;

function TDScintilla.GetExtraDescent: Integer;
begin
  Result := SendEditor(SCI_GETEXTRADESCENT, 0, 0);
end;

procedure TDScintilla.MarginSetText(ALine: Integer; const AText: UnicodeString);
begin
  FHelper.SetText(SCI_MARGINSETTEXT, ALine, AText);
end;

function TDScintilla.MarginGetText(ALine: Integer): UnicodeString;
begin
  FHelper.GetText(SCI_MARGINGETTEXT, ALine, Result);
end;

procedure TDScintilla.MarginSetStyle(ALine: Integer; AStyle: Integer);
begin
  SendEditor(SCI_MARGINSETSTYLE, ALine, AStyle);
end;

function TDScintilla.MarginGetStyle(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_MARGINGETSTYLE, ALine, 0);
end;

procedure TDScintilla.MarginSetStyles(ALine: Integer; const AStyles: TDSciStyles);
begin
  SendEditor(SCI_MARGINSETSTYLES, ALine, Integer(AStyles));
end;

function TDScintilla.MarginGetStyles(ALine: Integer): TDSciStyles;
begin
  SetLength(Result, SendEditor(SCI_MARGINGETSTYLES, ALine));
  if Length(Result) > 0 then
    SendEditor(SCI_MARGINGETSTYLES, ALine, Integer(Result));
end;

procedure TDScintilla.MarginSetStyleOffset(AStyle: Integer);
begin
  SendEditor(SCI_MARGINSETSTYLEOFFSET, AStyle, 0);
end;

function TDScintilla.MarginGetStyleOffset: Integer;
begin
  Result := SendEditor(SCI_MARGINGETSTYLEOFFSET, 0, 0);
end;

procedure TDScintilla.SetMarginOptions(AMarginOptions: Integer);
begin
  SendEditor(SCI_SETMARGINOPTIONS, AMarginOptions, 0);
end;

function TDScintilla.GetMarginOptions: Integer;
begin
  Result := SendEditor(SCI_GETMARGINOPTIONS, 0, 0);
end;

procedure TDScintilla.AnnotationSetText(ALine: Integer; const AText: UnicodeString);
begin
  FHelper.SetText(SCI_ANNOTATIONSETTEXT, ALine, AText);
end;

function TDScintilla.AnnotationGetText(ALine: Integer): UnicodeString;
begin
  FHelper.SetText(SCI_ANNOTATIONGETTEXT, ALine, Result);
end;
procedure TDScintilla.AnnotationSetStyle(ALine: Integer; AStyle: Integer);
begin
  SendEditor(SCI_ANNOTATIONSETSTYLE, ALine, AStyle);
end;

function TDScintilla.AnnotationGetStyle(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_ANNOTATIONGETSTYLE, ALine, 0);
end;

procedure TDScintilla.AnnotationSetStyles(ALine: Integer; const AStyles: TDSciStyles);
begin
  SendEditor(SCI_ANNOTATIONSETSTYLES, ALine, Integer(AStyles));
end;

function TDScintilla.AnnotationGetStyles(ALine: Integer): TDSciStyles;
begin
  SetLength(Result, SendEditor(SCI_ANNOTATIONGETSTYLES, ALine));
  if Length(Result) > 0 then
    SendEditor(SCI_ANNOTATIONGETSTYLES, ALine, Integer(Result));
end;

function TDScintilla.AnnotationGetLines(ALine: Integer): Integer;
begin
  Result := SendEditor(SCI_ANNOTATIONGETLINES, ALine, 0);
end;

procedure TDScintilla.AnnotationSetVisible(AVisible: Integer);
begin
  SendEditor(SCI_ANNOTATIONSETVISIBLE, AVisible, 0);
end;

function TDScintilla.AnnotationGetVisible: Integer;
begin
  Result := SendEditor(SCI_ANNOTATIONGETVISIBLE, 0, 0);
end;

procedure TDScintilla.AnnotationSetStyleOffset(AStyle: Integer);
begin
  SendEditor(SCI_ANNOTATIONSETSTYLEOFFSET, AStyle, 0);
end;

function TDScintilla.AnnotationGetStyleOffset: Integer;
begin
  Result := SendEditor(SCI_ANNOTATIONGETSTYLEOFFSET, 0, 0);
end;

procedure TDScintilla.SetMouseSelectionRectangularSwitch(AMouseSelectionRectangularSwitch: Boolean);
begin
  SendEditor(SCI_SETMOUSESELECTIONRECTANGULARSWITCH, Integer(AMouseSelectionRectangularSwitch), 0);
end;

function TDScintilla.GetMouseSelectionRectangularSwitch: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETMOUSESELECTIONRECTANGULARSWITCH, 0, 0));
end;

procedure TDScintilla.SetMultipleSelection(AMultipleSelection: Boolean);
begin
  SendEditor(SCI_SETMULTIPLESELECTION, Integer(AMultipleSelection), 0);
end;

function TDScintilla.GetMultipleSelection: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETMULTIPLESELECTION, 0, 0));
end;

procedure TDScintilla.SetAdditionalSelectionTyping(AAdditionalSelectionTyping: Boolean);
begin
  SendEditor(SCI_SETADDITIONALSELECTIONTYPING, Integer(AAdditionalSelectionTyping), 0);
end;

function TDScintilla.GetAdditionalSelectionTyping: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETADDITIONALSELECTIONTYPING, 0, 0));
end;

procedure TDScintilla.SetAdditionalCaretsBlink(AAdditionalCaretsBlink: Boolean);
begin
  SendEditor(SCI_SETADDITIONALCARETSBLINK, Integer(AAdditionalCaretsBlink), 0);
end;

function TDScintilla.GetAdditionalCaretsBlink: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETADDITIONALCARETSBLINK, 0, 0));
end;

procedure TDScintilla.SetAdditionalCaretsVisible(AAdditionalCaretsBlink: Boolean);
begin
  SendEditor(SCI_SETADDITIONALCARETSVISIBLE, Integer(AAdditionalCaretsBlink), 0);
end;

function TDScintilla.GetAdditionalCaretsVisible: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETADDITIONALCARETSVISIBLE, 0, 0));
end;

function TDScintilla.GetSelections: Integer;
begin
  Result := SendEditor(SCI_GETSELECTIONS, 0, 0);
end;

function TDScintilla.GetSelectionEmpty: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETSELECTIONEMPTY, 0, 0));
end;

procedure TDScintilla.SetMainSelection(ASelection: Integer);
begin
  SendEditor(SCI_SETMAINSELECTION, ASelection, 0);
end;

function TDScintilla.GetMainSelection: Integer;
begin
  Result := SendEditor(SCI_GETMAINSELECTION, 0, 0);
end;

procedure TDScintilla.SetSelectionNCaret(ASelection: Integer; APos: Integer);
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    SendEditor(SCI_SETSELECTIONNCARET, ASelection, APos);
end;

function TDScintilla.GetSelectionNCaret(ASelection: Integer): Integer;
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    Result := SendEditor(SCI_GETSELECTIONNCARET, ASelection, 0)
  else
    Result := INVALID_POSITION;
end;

procedure TDScintilla.SetSelectionNAnchor(ASelection: Integer; APosAnchor: Integer);
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    SendEditor(SCI_SETSELECTIONNANCHOR, ASelection, APosAnchor);
end;

function TDScintilla.GetSelectionNAnchor(ASelection: Integer): Integer;
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    Result := SendEditor(SCI_GETSELECTIONNANCHOR, ASelection, 0)
  else
    Result := INVALID_POSITION;
end;

procedure TDScintilla.SetSelectionNCaretVirtualSpace(ASelection: Integer; ASpace: Integer);
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    SendEditor(SCI_SETSELECTIONNCARETVIRTUALSPACE, ASelection, ASpace);
end;

function TDScintilla.GetSelectionNCaretVirtualSpace(ASelection: Integer): Integer;
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    Result := SendEditor(SCI_GETSELECTIONNCARETVIRTUALSPACE, ASelection, 0)
  else
    Result := INVALID_POSITION;
end;

procedure TDScintilla.SetSelectionNAnchorVirtualSpace(ASelection: Integer; ASpace: Integer);
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    SendEditor(SCI_SETSELECTIONNANCHORVIRTUALSPACE, ASelection, ASpace);
end;

function TDScintilla.GetSelectionNAnchorVirtualSpace(ASelection: Integer): Integer;
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    Result := SendEditor(SCI_GETSELECTIONNANCHORVIRTUALSPACE, ASelection, 0)
  else
    Result := INVALID_POSITION;
end;

procedure TDScintilla.SetSelectionNStart(ASelection: Integer; APos: Integer);
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    SendEditor(SCI_SETSELECTIONNSTART, ASelection, APos);
end;

function TDScintilla.GetSelectionNStart(ASelection: Integer): Integer;
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    Result := SendEditor(SCI_GETSELECTIONNSTART, ASelection, 0)
  else
    Result := INVALID_POSITION;
end;

procedure TDScintilla.SetSelectionNEnd(ASelection: Integer; APos: Integer);
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    SendEditor(SCI_SETSELECTIONNEND, ASelection, APos);
end;

function TDScintilla.GetSelectionNEnd(ASelection: Integer): Integer;
begin
  if (ASelection >= 0) and (ASelection < GetSelections) then
    Result := SendEditor(SCI_GETSELECTIONNEND, ASelection, 0)
  else
    Result := INVALID_POSITION;
end;

procedure TDScintilla.SetRectangularSelectionCaret(APos: Integer);
begin
  SendEditor(SCI_SETRECTANGULARSELECTIONCARET, APos, 0);
end;

function TDScintilla.GetRectangularSelectionCaret: Integer;
begin
  Result := SendEditor(SCI_GETRECTANGULARSELECTIONCARET, 0, 0);
end;

procedure TDScintilla.SetRectangularSelectionAnchor(APosAnchor: Integer);
begin
  SendEditor(SCI_SETRECTANGULARSELECTIONANCHOR, APosAnchor, 0);
end;

function TDScintilla.GetRectangularSelectionAnchor: Integer;
begin
  Result := SendEditor(SCI_GETRECTANGULARSELECTIONANCHOR, 0, 0);
end;

procedure TDScintilla.SetRectangularSelectionCaretVirtualSpace(ASpace: Integer);
begin
  SendEditor(SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE, ASpace, 0);
end;

function TDScintilla.GetRectangularSelectionCaretVirtualSpace: Integer;
begin
  Result := SendEditor(SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE, 0, 0);
end;

procedure TDScintilla.SetRectangularSelectionAnchorVirtualSpace(ASpace: Integer);
begin
  SendEditor(SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE, ASpace, 0);
end;

function TDScintilla.GetRectangularSelectionAnchorVirtualSpace: Integer;
begin
  Result := SendEditor(SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE, 0, 0);
end;

procedure TDScintilla.SetVirtualSpaceOptions(AVirtualSpaceOptions: Integer);
begin
  SendEditor(SCI_SETVIRTUALSPACEOPTIONS, AVirtualSpaceOptions, 0);
end;

function TDScintilla.GetVirtualSpaceOptions: Integer;
begin
  Result := SendEditor(SCI_GETVIRTUALSPACEOPTIONS, 0, 0);
end;

procedure TDScintilla.SetRectangularSelectionModifier(AModifier: Integer);
begin
  SendEditor(SCI_SETRECTANGULARSELECTIONMODIFIER, AModifier, 0);
end;

function TDScintilla.GetRectangularSelectionModifier: Integer;
begin
  Result := SendEditor(SCI_GETRECTANGULARSELECTIONMODIFIER, 0, 0);
end;

procedure TDScintilla.SetAdditionalSelFore(AFore: TColor);
begin
  SendEditor(SCI_SETADDITIONALSELFORE, Integer(AFore), 0);
end;

procedure TDScintilla.SetAdditionalSelBack(ABack: TColor);
begin
  SendEditor(SCI_SETADDITIONALSELBACK, Integer(ABack), 0);
end;

procedure TDScintilla.SetAdditionalSelAlpha(AAlpha: Integer);
begin
  SendEditor(SCI_SETADDITIONALSELALPHA, AAlpha, 0);
end;

function TDScintilla.GetAdditionalSelAlpha: Integer;
begin
  Result := SendEditor(SCI_GETADDITIONALSELALPHA, 0, 0);
end;

procedure TDScintilla.SetAdditionalCaretFore(AFore: TColor);
begin
  SendEditor(SCI_SETADDITIONALCARETFORE, Integer(AFore), 0);
end;

function TDScintilla.GetAdditionalCaretFore: TColor;
begin
  Result := TColor(SendEditor(SCI_GETADDITIONALCARETFORE, 0, 0));
end;

procedure TDScintilla.SetIdentifier(AIdentifier: Integer);
begin
  SendEditor(SCI_SETIDENTIFIER, AIdentifier, 0);
end;

function TDScintilla.GetIdentifier: Integer;
begin
  Result := SendEditor(SCI_GETIDENTIFIER, 0, 0);
end;

procedure TDScintilla.RGBAImageSetWidth(AWidth: Integer);
begin
  SendEditor(SCI_RGBAIMAGESETWIDTH, AWidth, 0);
end;

procedure TDScintilla.RGBAImageSetHeight(AHeight: Integer);
begin
  SendEditor(SCI_RGBAIMAGESETHEIGHT, AHeight, 0);
end;

procedure TDScintilla.SetTechnology(ATechnology: Integer);
begin
  SendEditor(SCI_SETTECHNOLOGY, ATechnology, 0);
end;

function TDScintilla.GetTechnology: Integer;
begin
  Result := SendEditor(SCI_GETTECHNOLOGY, 0, 0);
end;

function TDScintilla.GetCaretLineVisibleAlways: Boolean;
begin
  Result := Boolean(SendEditor(SCI_GETCARETLINEVISIBLEALWAYS, 0, 0));
end;

procedure TDScintilla.SetCaretLineVisibleAlways(AAlwaysVisible: Boolean);
begin
  SendEditor(SCI_SETCARETLINEVISIBLEALWAYS, Integer(AAlwaysVisible), 0);
end;

procedure TDScintilla.SetLineEndTypesAllowed(ALineEndBitSet: Integer);
begin
  SendEditor(SCI_SETLINEENDTYPESALLOWED, ALineEndBitSet, 0);
end;

function TDScintilla.GetLineEndTypesAllowed: Integer;
begin
  Result := SendEditor(SCI_GETLINEENDTYPESALLOWED, 0, 0);
end;

function TDScintilla.GetLineEndTypesActive: Integer;
begin
  Result := SendEditor(SCI_GETLINEENDTYPESACTIVE, 0, 0);
end;

procedure TDScintilla.SetRepresentation(AEncodedCharacter: AnsiString; ARepresentation: AnsiString);
begin
  FHelper.SetTextA(SCI_SETREPRESENTATION, Integer(FHelper.GetPtrFromAStr(AEncodedCharacter)), ARepresentation);
end;

function TDScintilla.GetRepresentation(AEncodedCharacter: AnsiString): AnsiString;
begin
  FHelper.GetTextA(SCI_GETREPRESENTATION, Integer(FHelper.GetPtrFromAStr(AEncodedCharacter)), Result);
end;

procedure TDScintilla.SetLexer(ALexer: Integer);
begin
  SendEditor(SCI_SETLEXER, ALexer, 0);
end;

function TDScintilla.GetLexer: Integer;
begin
  Result := SendEditor(SCI_GETLEXER, 0, 0);
end;

procedure TDScintilla.SetProperty(const AKey: UnicodeString; const AValue: UnicodeString);
begin
  if AKey <> '' then
    SendEditor(SCI_SETPROPERTY, NativeInt(AnsiString(AKey)), NativeInt(AnsiString(AValue)));
end;

function TDScintilla.GetPropertyInt(const AKey: UnicodeString; ADefault: Integer): Integer;
begin
  if AKey = '' then
    Result := ADefault
  else
    Result := SendEditor(SCI_GETPROPERTYINT, NativeInt(AnsiString(AKey)), ADefault);
end;

function TDScintilla.GetStyleBitsNeeded: Integer;
begin
  Result := SendEditor(SCI_GETSTYLEBITSNEEDED, 0, 0);
end;

function TDScintilla.GetLexerLanguage: UnicodeString;
begin
  FHelper.GetText(SCI_GETLEXERLANGUAGE, 0, Result);
end;

function TDScintilla.GetLineEndTypesSupported: Integer;
begin
  Result := SendEditor(SCI_GETLINEENDTYPESSUPPORTED, 0, 0);
end;

function TDScintilla.GetSubStylesStart(AStyleBase: Integer): Integer;
begin
  Result := SendEditor(SCI_GETSUBSTYLESSTART, AStyleBase, 0);
end;

function TDScintilla.GetSubStylesLength(AStyleBase: Integer): Integer;
begin
  Result := SendEditor(SCI_GETSUBSTYLESLENGTH, AStyleBase, 0);
end;

function TDScintilla.GetStyleFromSubStyle(ASubStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_GETSTYLEFROMSUBSTYLE, ASubStyle, 0);
end;

function TDScintilla.GetPrimaryStyleFromStyle(AStyle: Integer): Integer;
begin
  Result := SendEditor(SCI_GETPRIMARYSTYLEFROMSTYLE, AStyle, 0);
end;

procedure TDScintilla.SetIdentifiers(AStyle: Integer; const AIdentifiers: AnsiString);
begin
  FHelper.SetTextA(SCI_SETIDENTIFIERS, AStyle, AIdentifiers);
end;

function TDScintilla.DistanceToSecondaryStyles: Integer;
begin
  Result := SendEditor(SCI_DISTANCETOSECONDARYSTYLES, 0, 0);
end;

function TDScintilla.GetSubStyleBases: UnicodeString;
begin
  FHelper.GetText(SCI_GETSUBSTYLEBASES, 0, Result);
end;

// function TDScintilla.GetUsePalette: Boolean;
// begin
//   Result := Boolean(SendEditor(SCI_GETUSEPALETTE, 0, 0));
// end;

// procedure TDScintilla.SetUsePalette(AUsePalette: Boolean);
// begin
//   SendEditor(SCI_SETUSEPALETTE, Integer(AUsePalette), 0);
// end;

procedure TDScintilla.AnnotationSetText(ALine: Integer);
begin
  SendEditor(SCI_ANNOTATIONSETTEXT, ALine, 0);
end;

{$ENDREGION 'Scintilla properties CODE'}
//{$I DScintillaPropertiesCode.inc}

procedure TDScintilla.SetFocus;
begin
  inherited SetFocus;
end;

procedure TDScintilla.EnsureRangeVisible(APosStart, APosEnd: Integer);
var
  lLineStart, lLineEnd, lLine: Integer;
begin
  lLineStart := LineFromPosition(Min(APosStart, APosEnd));
  lLineEnd := LineFromPosition(Max(APosStart, APosEnd));

  for lLine := lLineStart to lLineEnd do
    EnsureVisible(lLine);
end;

end.

