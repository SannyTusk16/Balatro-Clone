function love.keypressed(key)
    if key == "escape" then
        if love.window.getFullscreen() == false then
            love.event.quit()
        else
            love.window.setFullscreen(false)
        end
    end

    if key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end

    if key == "f5" then
        love.event.quit("restart")
    end
    
    if key == "r" then
        -- Replace a random card with a new unused card
        local card_to_replace = math.random(8)
        local new_card = getNewCard()
        if new_card then
            card[card_to_replace].suit = new_card.suit
            card[card_to_replace].number = new_card.number
            card[card_to_replace].color = card_colors[new_card.suit]
            card[card_to_replace].selected = false
            card[card_to_replace].in_hand = false
            print("Replaced card " .. card_to_replace .. " with " .. card_numbers[new_card.number] .. card_suits[new_card.suit])
        end
    end
    
    if key == "return" or key == "enter" then
        -- Calculate score for current hand
        if #hand >= 1 and #hand <= 5 then
            calculateHandScore()
            refillCards()
        else
            print("Hand must contain 1-5 cards. Current hand size: " .. #hand)
        end
    end
    
    if key == "lshift" or key == "rshift" then
        -- Discard selected cards without scoring
        if #hand >= 1 then
            print("Discarding " .. #hand .. " selected cards")
            refillCards()
            hand = {} -- Clear hand without scoring
        else
            print("No cards selected to discard")
        end
    end

end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        -- Card selection logic
        for i = 1, 8 do
            if x >= card[i].x and x <= card[i].x + card[i].width and 
               y >= card[i].y and y <= card[i].y + card[i].length and
               card[i].suit and card[i].number then
                
                -- Check if we can select/deselect this card
                if card[i].selected then
                    -- Deselect card
                    card[i].selected = false
                    card[i].in_hand = false
                    -- Remove from hand
                    for j = #hand, 1, -1 do
                        if hand[j].card_index == i then
                            table.remove(hand, j)
                            break
                        end
                    end
                    print("Deselected card " .. i .. ": " .. card_numbers[card[i].number] .. card_suits[card[i].suit])
                elseif #hand < 5 then
                    -- Select card if hand not full
                    card[i].selected = true
                    card[i].in_hand = true
                    table.insert(hand, {
                        suit = card[i].suit,
                        number = card[i].number,
                        card_index = i
                    })
                    print("Selected card " .. i .. ": " .. card_numbers[card[i].number] .. card_suits[card[i].suit])
                    print("Hand size: " .. #hand)
                else
                    print("Hand is full! (5 cards maximum)")
                end
                break -- Exit loop once we've handled a card click
            end
        end
    end
end

function love.load()

    --Base resolution
    baseWidth = 1920
    baseHeight = 1080

    --Player setup
    player = {}
    player.x = 300
    player.y = 300
    player.size = 10

    --Keyboard setup
    keyb={}
    keyb.x =100
    keyb.y =50
    keyb.size =50
    keyb.up = love.keyboard.isDown("w")
    keyb.down = love.keyboard.isDown("s")
    keyb.left = love.keyboard.isDown("a")
    keyb.right = love.keyboard.isDown("d")

    -- box
    box = {}

    --Cards
    card = {}
    card_colors = {
        {1, 1, 1},           -- Spades - White (255,255,255)
        {82/255, 32/255, 27/255},  -- Hearts - Dark Red (82,32,27)
        {82/255 * 0.7, 32/255 * 0.7, 27/255 * 0.7},  -- Diamonds - Faded Hearts
        {1 * 0.7, 1 * 0.7, 1 * 0.7}   -- Clubs - Faded White (Gray)
    }
    card_suits = {"♠", "♥", "♦", "♣"}  -- Spades, Hearts, Diamonds, Clubs
    card_numbers = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}
    
    -- Load suit images
    suit_images = {}
    suit_images[1] = love.graphics.newImage("assets/spade.png")   -- Spades
    suit_images[2] = love.graphics.newImage("assets/heart.png")  -- Hearts  
    suit_images[3] = love.graphics.newImage("assets/diamond.png") -- Diamonds
    suit_images[4] = love.graphics.newImage("assets/club.png")   -- Clubs
    
    -- Create deck of 52 cards
    deck = {}
    for suit = 1, 4 do
        for number = 1, 13 do
            table.insert(deck, {suit = suit, number = number, color = card_colors[suit]})
        end
    end
    
    -- Initialize 8 display cards
    for i = 1, 8 do
        card[i] = {}
        card[i].dragging = false
        card[i].selected = false
        card[i].in_hand = false
        
        -- Pick random card from remaining deck and remove it
        if #deck > 0 then
            local random_index = math.random(#deck)
            local selected_card = deck[random_index]
            
            card[i].suit = selected_card.suit
            card[i].number = selected_card.number
            card[i].color = card_colors[selected_card.suit]
            
            -- Remove the card from the deck
            table.remove(deck, random_index)
        end
    end

    -- Poker hand definitions
    poker_hand_title = {
        "Straight Flush", 
        "Four of a Kind",
        "Full House",
        "Flush",
        "Straight",
        "Three of a Kind",
        "Two Pair",
        "Pair",
        "High Card"
    }

    poker_hand_desc = {
        "Five cards of the same suit in sequence.", 
        "Four cards of the same rank.",
        "Three of a kind and a pair.",
        "Five cards of the same suit.",
        "Five cards in sequence.",
        "Three cards of the same rank.",
        "Two different pairs.",
        "Two cards of the same rank.",
        "Highest card wins."
    }

    poker_hand_base_score = {
        160,  -- Flush Five
        100,  -- Straight Flush
        60,   -- Four of a Kind
        40,   -- Full House
        35,   -- Flush
        30,   -- Straight
        30,   -- Three of a Kind
        20,   -- Two Pair
        10,   -- Pair
        5     -- High Card
    }

    poker_hand_multiplier = {
        16,   -- Flush Five
        8,    -- Straight Flush
        7,    -- Four of a Kind
        4,    -- Full House
        4,    -- Flush
        4,    -- Straight
        3,    -- Three of a Kind
        2,    -- Two Pair
        2,    -- Pair
        1     -- High Card
    }

    poker_hand_freq = {
        0,  -- Flush Five
        0,  -- Straight Flush
        0,  -- Four of a Kind
        0,  -- Full House
        0,  -- Flush
        0,  -- Straight
        0,  -- Three of a Kind
        0,  -- Two Pair
        0,  -- Pair
        0   -- High Card
    }

    --Game State
    game_state = "playing" -- "playing", "gameover"
    state = {}
    state.score = 0

    hand = {}
    
    -- Card values for scoring
    card_values = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13} -- A=1, J=11, Q=12, K=13

    calculateSizes()

end

-- Function to get a new random card from remaining deck
function getNewCard()
    if #deck > 0 then
        local random_index = math.random(#deck)
        local selected_card = deck[random_index]
        
        -- Remove the card from deck and return it
        table.remove(deck, random_index)
        
        print("Drew card: " .. card_numbers[selected_card.number] .. card_suits[selected_card.suit])
        print("Cards remaining in deck: " .. #deck)
        
        return {
            suit = selected_card.suit,
            number = selected_card.number
        }
    end
    print("No cards left in deck!")
    return nil -- No cards left
end

-- Function to calculate hand score and add to total
function calculateHandScore()
    if #hand == 0 then return end
    
    -- Calculate base card score (sum of card values)
    local cardScore = 0
    for i = 1, #hand do
        cardScore = cardScore + card_values[hand[i].number]
    end
    
    -- Determine poker hand type
    local handType = checkPokerHands(hand)
    local handName = poker_hand_title[handType]
    local baseScore = poker_hand_base_score[handType]
    local multiplier = poker_hand_multiplier[handType]
    
    -- Calculate total score: (card values + hand base score) * multiplier
    local totalScore = (cardScore + baseScore) * multiplier
    
    -- Update frequency counter
    poker_hand_freq[handType] = poker_hand_freq[handType] + 1
    
    -- Add to total score
    state.score = state.score + totalScore
    
    print("=== HAND SCORED ===")
    print("Hand: " .. handName)
    print("Cards: ")
    for i = 1, #hand do
        print(card_numbers[hand[i].number] .. card_suits[hand[i].suit] .. " ")
    end
    print("")
    print("Card values total: " .. cardScore)
    print("Hand base score: " .. baseScore)
    print("Multiplier: " .. multiplier .. "x")
    print("Total hand score: " .. totalScore)
    print("New total score: " .. state.score)
    print("===================")
    
    -- Clear hand
    hand = {}
end

-- Function to refill card grid after scoring
function refillCards()
    for i = 1, 8 do
        if card[i].selected then
            -- Replace selected cards with new ones from deck
            local new_card = getNewCard()
            if new_card then
                card[i].suit = new_card.suit
                card[i].number = new_card.number
                card[i].color = card_colors[new_card.suit]
            else
                -- No more cards in deck
                card[i].suit = nil
                card[i].number = nil
                card[i].color = nil
            end
            card[i].selected = false
            card[i].in_hand = false
        end
    end
    print("Grid refilled. Cards remaining in deck: " .. #deck)
end

function love.update(dt)
    player.x = love.mouse.getX()
    player.y = love.mouse.getY()

    if love.keyboard.isDown("w") then
        keyb.y = keyb.y - 200 * dt
    end
    if love.keyboard.isDown("s") then
        keyb.y = keyb.y + 200 * dt
    end
    if love.keyboard.isDown("a") then
        keyb.x = keyb.x - 200 * dt
    end
    if love.keyboard.isDown("d") then
        keyb.x = keyb.x + 200 * dt
    end

    -- Card selection logic is now handled in love.mousepressed() callback
end

function checkPokerHands(hand)

    local sortedHand = {}
    for i = 1, #hand do
        table.insert(sortedHand, {suit = hand[i].suit, number = hand[i].number})
    end
    table.sort(sortedHand, function(a, b) return a.number < b.number end)

    -- Count occurrences of each number and suit
    local numberCounts = {}
    local suitCounts = {}
    for i = 1, #sortedHand do
        local num = sortedHand[i].number
        local suit = sortedHand[i].suit
        numberCounts[num] = (numberCounts[num] or 0) + 1
        suitCounts[suit] = (suitCounts[suit] or 0) + 1
    end

    -- Helper function to check if hand is a straight
    local function isStraight(hand)
        if #hand ~= 5 then return false end
        for i = 2, #hand do
            if hand[i].number ~= hand[i-1].number + 1 then
                -- Check for Ace-low straight (A,2,3,4,5)
                if i == 2 and hand[1].number == 1 and hand[2].number == 2 and 
                   hand[3].number == 3 and hand[4].number == 4 and hand[5].number == 5 then
                    return true
                end
                return false
            end
        end
        return true
    end

    -- Helper function to check if hand is a flush
    local function isFlush(hand)
        if #hand ~= 5 then return false end
        local firstSuit = hand[1].suit
        for i = 2, #hand do
            if hand[i].suit ~= firstSuit then
                return false
            end
        end
        return true
    end

    -- Count pairs, three of a kinds, etc.
    local pairCount = 0
    local threeOfAKind = false
    local fourOfAKind = false
    for num, count in pairs(numberCounts) do
        if count == 2 then
            pairCount = pairCount + 1
        elseif count == 3 then
            threeOfAKind = true
        elseif count == 4 then
            fourOfAKind = true
        end
    end

    -- Determine the best poker hand
    if #sortedHand == 5 then
        local flush = isFlush(sortedHand)
        local straight = isStraight(sortedHand)
        
        if flush and straight then
            -- Check for royal flush (10,J,Q,K,A of same suit)
            if sortedHand[1].number == 1 and sortedHand[2].number == 10 then
                return 1 -- Straight Flush (treating royal as straight flush)
            end
            return 1 -- Straight Flush
        elseif fourOfAKind then
            return 2 -- Four of a Kind
        elseif threeOfAKind and pairCount == 1 then
            return 3 -- Full House
        elseif flush then
            return 4 -- Flush
        elseif straight then
            return 5 -- Straight
        elseif threeOfAKind then
            return 6 -- Three of a Kind
        elseif pairCount == 2 then
            return 7 -- Two Pair
        elseif pairCount == 1 then
            return 8 -- Pair
        else
            return 9 -- High Card
        end
    else
        -- For hands with less than 5 cards, check what's possible
        if fourOfAKind then
            return 2 -- Four of a Kind
        elseif threeOfAKind and pairCount >= 1 then
            return 3 -- Full House
        elseif threeOfAKind then
            return 6 -- Three of a Kind
        elseif pairCount >= 2 then
            return 7 -- Two Pair
        elseif pairCount == 1 then
            return 8 -- Pair
        else
            return 9 -- High Card
        end
    end
end

function love.resize(w, h)

    local aspectRatio = 1920 / 1080
    local newAspect  = w / h

    if math.abs(newAspect - aspectRatio) > 0.01 then
        if newAspect > aspectRatio then
            w = h * aspectRatio
        else
            h = w / aspectRatio
        end
        love.window.setMode(w, h)
    end

    if w <960 or h<540 then
        w = math.max(w,960)
        h = math.max(h,540)
        love.window.setMode(w, h)
    end

    calculateSizes()
end


function calculateSizes()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Calc scaling factors
    local scaleX = screenWidth / baseWidth
    local scaleY = screenHeight / baseHeight
    
    -- Base sizes (designed for 1080p) - Static bar from reference measurements
    local baseBoxWidth = 1920  -- Full width
    local baseBoxLength = 349  -- Much taller static bar as shown in reference (about 1/3 of screen)
    local baseBoxX = 0         -- Full width from edge
    local baseBoxY = 62        -- 62px from top as shown in reference
    
    -- Cards arranged in 2x4 grid - larger cards matching reference proportions
    local baseCardWidth = 162  -- Larger card width to match reference
    local baseCardLength = 205 -- Larger card height to match reference
    local basePadding = 31     -- 31px padding between cards from reference
    
    -- Position grid using exact measurements from reference
    local gridTotalWidth = 4 * baseCardWidth + 3 * basePadding
    local gridTotalHeight = 2 * baseCardLength + basePadding
    
    -- Position based on reference - cards should be more centered in right area
    local rightAreaStart = 1920 * 0.5  -- Right half of screen roughly
    local rightAreaWidth = 1920 * 0.5 - 83  -- Right area minus margin
    local baseGridStartX = rightAreaStart + (rightAreaWidth - gridTotalWidth) / 2  -- Center in right area
    local availableBottomSpace = 1080 - (baseBoxY + baseBoxLength)
    local baseGridStartY = baseBoxY + baseBoxLength + (availableBottomSpace - gridTotalHeight) / 2

    -- Apply scaling to navigation box
    box.x = baseBoxX * scaleX
    box.y = baseBoxY * scaleY
    box.width = baseBoxWidth * scaleX
    box.length = baseBoxLength * scaleY

    -- Scale padding
    local cardPadding = basePadding * math.min(scaleX, scaleY)

    -- Apply scaling to cards in 2x4 grid
    for i = 1, 8 do
        local col = (i - 1) % 4  -- Column (0-3)
        local row = math.floor((i - 1) / 4)  -- Row (0-1)
        
        card[i].x = (baseGridStartX + col * (baseCardWidth + basePadding)) * scaleX
        card[i].y = (baseGridStartY + row * (baseCardLength + basePadding)) * scaleY
        card[i].width = baseCardWidth * scaleX
        card[i].length = baseCardLength * scaleY
    end
end


function love.draw()
    -- Dark background color matching wireframe
    love.graphics.setBackgroundColor(0.15, 0.15, 0.15) -- Dark gray background
    
    -- Draw top navigation bar (Static area)
    love.graphics.setColor(0.4, 0.45, 0.4) -- Olive green matching wireframe
    love.graphics.rectangle("fill", box.x, box.y, box.width, box.length)
    
    -- Draw game state info in the navigation bar
    love.graphics.setColor(1, 1, 1) -- White text
    local font = love.graphics.getFont()
    
    -- Score display
    local scoreText = "SCORE: " .. state.score
    love.graphics.print(scoreText, box.x + 20, box.y + 20)
    
    -- Hand info
    local handText = "HAND: " .. #hand .. "/5"
    if #hand > 0 then
        handText = handText .. " ("
        for i = 1, #hand do
            handText = handText .. card_numbers[hand[i].number] .. card_suits[hand[i].suit]
            if i < #hand then handText = handText .. ", " end
        end
        handText = handText .. ")"
    end
    love.graphics.print(handText, box.x + 20, box.y + 50)
    
    -- Instructions
    local instructText = "Click cards to select (1-5), then press ENTER to score"
    love.graphics.print(instructText, box.x + 20, box.y + 80)
    
    -- Show calculation if hand is selected
    if #hand > 0 then
        -- Calculate current hand preview
        local cardScore = 0
        for i = 1, #hand do
            cardScore = cardScore + card_values[hand[i].number]
        end
        
        local handType = checkPokerHands(hand)
        local handName = poker_hand_title[handType]
        local baseScore = poker_hand_base_score[handType]
        local multiplier = poker_hand_multiplier[handType]
        local totalScore = (cardScore + baseScore) * multiplier
        
        -- Display calculation
        local calcText = "CALCULATION: (" .. cardScore .. " + " .. baseScore .. ") × " .. multiplier .. " = " .. totalScore
        love.graphics.print(calcText, box.x + 20, box.y + 110)
        
        local handTypeText = "CURRENT HAND: " .. handName
        love.graphics.print(handTypeText, box.x + 20, box.y + 140)
    end

    -- Draw the cards with their suit and number
    for i = 1, 8 do
        
        -- Draw card content if card exists
        if card[i].suit and card[i].number then
            
            -- Draw card background using suit color
            local suit_color = card_colors[card[i].suit]
            love.graphics.setColor(suit_color[1], suit_color[2], suit_color[3])
            love.graphics.rectangle("fill", card[i].x, card[i].y, card[i].width, card[i].length)
            
            -- Add card border (highlight if selected)
            if card[i].selected then
                love.graphics.setColor(1, 1, 0) -- Yellow border for selected cards
                love.graphics.setLineWidth(3)
            else
                love.graphics.setColor(0.2, 0.2, 0.2) -- Dark border
                love.graphics.setLineWidth(1)
            end
            love.graphics.rectangle("line", card[i].x, card[i].y, card[i].width, card[i].length)
            love.graphics.setLineWidth(1) -- Reset line width
            
            -- Use contrasting color for text (white or black depending on background)
            local text_color = {1, 1, 1} -- Default to white text
            if card[i].suit == 1 then -- Spades (white background)
                text_color = {0, 0, 0} -- Black text on white background
            end
            love.graphics.setColor(text_color[1], text_color[2], text_color[3])
            
            -- Draw number in top-left
            local number_text = card_numbers[card[i].number]
            love.graphics.print(number_text, card[i].x + 5, card[i].y + 5)
            
            -- Draw suit image in center
            love.graphics.setColor(1, 1, 1) -- White tint for image
            local suit_image = suit_images[card[i].suit]
            local image_width = suit_image:getWidth()
            local image_height = suit_image:getHeight()
            -- Scale image to fit nicely in card (about 1/3 of card width)
            local scale = (card[i].width * 0.3) / image_width
            love.graphics.draw(suit_image, 
                card[i].x + card[i].width/2, 
                card[i].y + card[i].length/2, 
                0, scale, scale, image_width/2, image_height/2)
            
            -- Restore text color for bottom number
            love.graphics.setColor(text_color[1], text_color[2], text_color[3])
            
            -- Draw number in bottom-right (upside down)
            love.graphics.push()
            love.graphics.translate(card[i].x + card[i].width - 5, card[i].y + card[i].length - 5)
            love.graphics.rotate(math.pi)
            love.graphics.print(number_text, 0, 0)
            love.graphics.pop()
        end
    end


    --draw poker hand text area
    local poker_handAreaX = 83 * (love.graphics.getWidth() / baseWidth)
    local poker_handAreaY = (box.y + box.length + 20 * (love.graphics.getHeight() / baseHeight))
    local poker_handAreaWidth = (1920 * 0.5 - 83 - 20) * (love.graphics.getWidth() / baseWidth) -- Right half minus margins 
    local poker_handAreaHeight = (love.graphics.getHeight() - poker_handAreaY - 20) -- Bottom margin
    love.graphics.setColor(0.2, 0.2, 0.2) -- Dark gray background for poker_hand area
    love.graphics.rectangle("fill", poker_handAreaX, poker_handAreaY, poker_handAreaWidth, poker_handAreaHeight)
    -- Draw poker hands table in the hand area
    love.graphics.setColor(1, 1, 1) -- White text
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight() + 4
    local startY = poker_handAreaY + 10
    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredRow = nil

    -- Table headers
    love.graphics.print("Hand", poker_handAreaX + 10, startY)
    love.graphics.print("Score", poker_handAreaX + 180, startY)
    love.graphics.print("Mult", poker_handAreaX + 240, startY)
    love.graphics.print("Freq", poker_handAreaX + 280, startY)

    -- Draw a line under headers
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.line(poker_handAreaX + 5, startY + lineHeight, poker_handAreaX + poker_handAreaWidth - 5, startY + lineHeight)

    -- Draw each poker poker_hand row
    for i = 1, #poker_hand_title do
        local rowY = startY + lineHeight * (i + 1)
        
        -- Check if mouse is hovering over this row
        if mouseX >= poker_handAreaX and mouseX <= poker_handAreaX + poker_handAreaWidth and
           mouseY >= rowY and mouseY <= rowY + lineHeight then
            hoveredRow = i
            -- Highlight hovered row
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", poker_handAreaX + 5, rowY, poker_handAreaWidth - 10, lineHeight)
        end
        
        love.graphics.setColor(1, 1, 1) -- White text
        love.graphics.print(poker_hand_title[i], poker_handAreaX + 10, rowY)
        love.graphics.print(poker_hand_base_score[i], poker_handAreaX + 180, rowY)
        love.graphics.print(poker_hand_multiplier[i] .. "x", poker_handAreaX + 240, rowY)
        
        -- Show frequency with color coding
        local freq = poker_hand_freq[i]
        if freq > 0 then
            love.graphics.setColor(0.7, 1, 0.7) -- Light green for played hands
        else
            love.graphics.setColor(0.6, 0.6, 0.6) -- Gray for unplayed hands
        end
        love.graphics.print(freq, poker_handAreaX + 290, rowY)
    end

    -- Draw tooltip for hovered row
    if hoveredRow then
        local tooltipText = poker_hand_desc[hoveredRow]
        local tooltipWidth = font:getWidth(tooltipText) + 20
        local tooltipHeight = lineHeight + 10
        local tooltipX = mouseX + 15
        local tooltipY = mouseY - tooltipHeight / 2
        
        -- Keep tooltip within screen bounds
        if tooltipX + tooltipWidth > love.graphics.getWidth() then
            tooltipX = mouseX - tooltipWidth - 15
        end
        if tooltipY < 0 then tooltipY = 0 end
        if tooltipY + tooltipHeight > love.graphics.getHeight() then
            tooltipY = love.graphics.getHeight() - tooltipHeight
        end
        
        -- Draw tooltip background
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
        
        -- Draw tooltip border
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight)
        
        -- Draw tooltip text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tooltipText, tooltipX + 10, tooltipY + 5)
    end

    -- Remove the player circle and keyboard circle to match wireframe
    
    -- Controls display in top right
    love.graphics.setColor(1, 1, 1) -- White text
    local controlsText = "ENTER: HAND, SHIFT: DISCARD"
    local controlsTextWidth = font:getWidth(controlsText)
    love.graphics.print(controlsText, love.graphics.getWidth() - controlsTextWidth - 10, 10)
end