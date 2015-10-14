"""
Todolist:
  - syntax check before run
  - testExpression still buggggggggyyyyyyy
  - fileheader
  - much & more
"""
String.prototype.nthIndexOf = (pattern, n) ->
    i = -1;
    while n-- and i++ < this.length
        i = this.indexOf(pattern, i)
        if i < 0
          break
    return i

class irin
  data:
    graph: []
    head: []

  config:
    indent:
      len: 2

  constructor: (@steam, @option) ->
    #if have custom config then load custom config
    if @option and @option.indent
      if @option.indent.len
        @config.indent.len = @option.indent.len
    #parse irin language to graph
    @data.graph = @parse(@steam)
    @data.graph = {next:@data.graph}
    @data.head = @data.graph
  getGraph:()->
    return @data.graph
  parse: (@steam)->
    resultGraph = []
    currentGraph = resultGraph
    currentIndent = 0
    splitSteam = @steam.split "\n"
    multiLineComment = false
    functionObject = {}
    functionHead = []
    isAddtoFunction = false
    currentAddtoFunction = ""
    for text in splitSteam
      #remove Single line comment
      if text.indexOf("#") > -1
        text = text.substring(0,text.indexOf("#"));
      #remove Multi line Comment
      if multiLineComment
        if text.indexOf("\"\"\"") == -1
          continue
        else
          text = text.slice(text.indexOf("\"\"\"")+3)
          multiLineComment = false
      if text.indexOf("\"\"\"")> -1
        if not multiLineComment
          commentStartPos = text.indexOf("\"\"\"")
          text = text.slice(0, commentStartPos) + text.slice(commentStartPos+3);
          if text.indexOf("\"\"\"")> -1
            text = text.slice(0, commentStartPos) + text.slice(text.indexOf("\"\"\"")+3);
          else
            text = text.substring(0,commentStartPos)
            multiLineComment = true
      #count textIndent
      textIndent = text.search /\S/
      if textIndent == -1
        continue
      text = text.trim()
      textIndent = textIndent/@config.indent.len

      #function parse
      if text.substring(0,2) == "->"
        text = text.substring(2,text.length)
        text = text.trim()
        if textIndent == 0
        #declarefunction
          if not functionObject[text]
            functionObject[text] = []
          currentAddtoFunction = text
          isAddtoFunction = true
          functionHead = functionObject[text]
          continue
        #activefunction
        else
          if currentIndent == textIndent
            cloneObj.depth = currentIndent
            currentGraph.push(functionObject[text].next)
          else if textIndent>currentIndent
            if not functionObject[text]
              functionObject[text] = []
            currentGraph[currentGraph.length-1].next = functionObject[text]
            continue
      #add to graph
      #add to functionObject
      if isAddtoFunction
        if textIndent is currentIndent
          functionHead.push {text:text,depth:textIndent,next:[]}
          if functionHead.length > 1
            functionHead[functionHead.length - 2].next = functionHead[functionHead.length - 1].next
        else if textIndent > currentIndent
          currentIndent = textIndent
          functionHead = functionHead[functionHead.length-1].next
          functionHead.push {text:text,depth:textIndent,next:[]}
        else
          # if textIndent is zero so it end of function declare
          if textIndent == 0
            currentAddtoFunction = ""
            isAddtoFunction = false
            currentGraph = resultGraph
            currentIndent = 0
            while textIndent != currentIndent
              currentIndent++
              currentGraph = currentGraph[currentGraph.length-1].next
            currentGraph.push {text:text,depth:textIndent,next:[]}
          else
            functionHead = resultGraph
            currentIndent = 0
            while textIndent != currentIndent
              currentIndent++
              functionHead = functionHead[functionHead.length-1].next
            functionHead.push {text:text,depth:textIndent,next:[]}
      #add to resultGraph
      else
        if textIndent is currentIndent
          currentGraph.push {text:text,depth:textIndent,next:[]}
          #pointer link to same child for multiqustion on same answer
          if currentGraph.length > 1
            currentGraph[currentGraph.length - 2].next = currentGraph[currentGraph.length - 1].next
        #travle deeper
        else if textIndent > currentIndent
          currentIndent = textIndent
          currentGraph = currentGraph[currentGraph.length-1].next
          currentGraph.push {text:text,depth:textIndent,next:[]}
        #end of route so restart new at root
        else
          currentGraph = resultGraph
          currentIndent = 0
          while textIndent != currentIndent
            currentIndent++
            currentGraph = currentGraph[currentGraph.length-1].next
          currentGraph.push {text:text,depth:textIndent,next:[]}
    return resultGraph

  testExpression: (@text,@expression)->
    # maybe still bug
    #(blankspace is a big problem)
    unuseArray = []
    processed = ""
    isInbracket = false
    isSkipspace = false
    isCutLastSpace = false
    if @expression[@expression.length-1] == "]"
      lastSpaceLocation = 0
      lastSpaceLocation = @expression.lastIndexOf("[")-1
      if(@expression[lastSpaceLocation]==" ")
        @expression = @expression.slice(0,lastSpaceLocation)+@expression.slice(lastSpaceLocation+1,@expression.length)
        isCutLastSpace = true
    for ch in @expression
      #avoid space after optional expression
      if ch == " " and isSkipspace
          isSkipspace = false
          continue
      else if ch ==" "
        isSkipspace = false
        processed += ch
        continue
      else if ch == "["
        processed += "( |"
        isInbracket = true
        unuseArray.push("[");
      else if ch == "]"
        processed += ")?"
        isInbracket = false
        isSkipspace = true
      else if ch == "*"
        if isInbracket
          processed+=".+"
        else
          processed+="(.+)"
      else if ch == "("
        unuseArray.push("(");
        processed+="("
      else
        processed+=ch
    nProcessed = processed
    processed = new RegExp(processed)
    if not processed.test(@text)
      return undefined
    parsedArray = @text.match(processed)
    #fix wrong laststring word tokenization detect on ELIZA
    if isCutLastSpace and parsedArray[parsedArray.length-1] != undefined
      index = nProcessed.lastIndexOf("(")
      nProcessed = nProcessed.slice(0,index)+" "+nProcessed.slice(index,nProcessed.length)
      processed = new RegExp(nProcessed)
      if not processed.test(@text)
        return undefined
      parsedArray = @text.match(processed)
    parsedArray.splice(0,1)
    while (index = unuseArray.indexOf("[")) > -1
      parsedArray.splice(index,2)
      unuseArray.splice(index,1)
    resultArray = []
    for element in parsedArray
      resultArray.push(element.trim())
    return resultArray

  mergeExpression: (@expression,@rData)->
    #Todo : merge array to answer before output
    buffer = ""
    openBracket = false
    for ch in @expression
      if ch is "{"
        openBracket = true
      else if ch is "}"
        @expression = @expression.slice(0, @expression.indexOf("{"))+@rData[parseInt(buffer)-1]+@expression.slice(@expression.indexOf("}")+1)
        openBracket = false
        buffer = ""
      else if openBracket
        buffer+=ch
    return @expression

  selectChild: (@text, @head)->
    for child in @head.next
      #this condition need to change to regular expression "later"
      if answerData = @testExpression(@text,child.text)
        select = Math.floor(Math.random()*child.next.length)
        return {node:child.next[select],data:answerData}
    return undefined

  reply: (@text)->
    answer = @selectChild(@text,@data.head)
    if answer
      @data.head = answer.node
      return @mergeExpression(answer.node.text,answer.data)
    @data.head = @data.graph
    answer = @selectChild(@text,@data.head)
    if answer
      @data.head = answer.node
      return @mergeExpression(answer.node.text,answer.data)
    return "[Log:Error] answer not found"

module.exports = irin
