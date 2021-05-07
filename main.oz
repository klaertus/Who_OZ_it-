functor
import
   ProjectLib
   Browser
   OS
   %System
   Application
   Open
define
   CWD = {Atom.toString {OS.getCWD}}#"/"
   Browse = proc {$ Buf} {Browser.browse Buf} end
   %Print = proc{$ S} {System.print S} end
   Args = {Application.getArgs record('nogui'(single type:bool default:false optional:true)
									  'db'(single type:string default:CWD#"database.txt")
                             'ans'(single type:string default:CWD#"test_answers.txt"))} 
in 
   local
	   NoGUI = Args.'nogui'
      ListOfAnswers ={ProjectLib.loadCharacter file Args.'ans' }  
      %NewCharacter = {ProjectLib.loadCharacter file Args.'newChar'}
      DATABASE = {ProjectLib.loadDatabase file Args.'db'}
      
      Filename = stdout
      OutputFile = {New Open.file init(name: Filename
                  flags: [write create truncate text])}

      fun{BestQuestionsAux DATA QL NT NF BR BQ}
         %DATA : Data base
         %QL : Questions list
         %NT : Number of Trues
         %NF : Number of Falses
         %BR : Best Ratio
         %BQ Best Question
         %Return : {BestQuestion} with one less question
         case DATA
         of nil then
            if {Number.abs (NT/NF)} < BR then
         {BestQuestion DATABASE QL.2 {Number.abs (NT/NF)} QL.1} 
            else {BestQuestion DATABASE QL.2 BR BQ}
            end
         [] H|T then
            if {Value.condSelect H QL.1 "e"} == true then {BestQuestionsAux T QL NT+1.0 NF BR BQ}
            else {BestQuestionsAux T QL NT NF+1.0 BR BQ}
            end
         end
      end

      fun{BestQuestion DATA QL BR BQ}
         %DATA : Data base
         %QL : Questions list
         %BR : Best Ratio
         %BQ Best Question
         %Return : The best question
         case QL
         of nil then BQ
         [] H|T then
            {BestQuestionsAux DATA QL 0.0 0.0 BR BQ}
         end
      end

      fun {OrderedQuestions DATA QL}
         case QL
         of nil then nil
         []H|T then
            {Browse {BestQuestion DATABASE QL 255.0 H}}
            {OrderedQuestions DATABASE {List.subtract QL {BestQuestion DATABASE QL 255.0 H}}}
         end   
      end

      fun {Characters DATA Q A}
         %DATA : data base
         %Q : a question
         %A : the expected answer
         %Return : the data base with characters having the right answer only
         case DATA
         of nil then nil
         [] H|T then
            if A == 'TRUE' then
         if {Value.condSelect H Q 'error'} == true then
            H|{Characters T Q A}
         else
            {Characters T Q A}
         end
            else
         if {Value.condSelect H Q 'error'} == false then
            H|{Characters T Q A}
         else
            {Characters T Q A}
         end
            end
         end
      end

      fun {Names DATA}
         %DATA : data base
         %Return : names of characters in DATA
         case DATA
         of nil then nil
         [] H|T then
            H.1|{Names T}
         end
      end

      fun {BuildDecisionTree DATA QL}
               %DATA : database
               %QL : list of questions
               %Return : a decisions tree
               
               
               if {List.length DATA} == 1 then leaf([DATA.1.1])
               elseif DATA == nil then nil
               elseif QL == nil then leaf({Names DATA})
               elseif {Characters DATA {BestQuestion DATA QL 255.0 QL.1} 'TRUE'} \= nil then
                     if {Characters DATA {BestQuestion DATA QL 255.0 QL.1} 'FALSE'} \= nil then
                        question({BestQuestion DATA QL 255.0 QL.1}
                           true : {BuildDecisionTree {Characters DATA {BestQuestion DATA QL 255.0 QL.1} 'TRUE'} {List.subtract QL {BestQuestion DATA QL 255.0 QL.1}}}
                           false : {BuildDecisionTree {Characters DATA {BestQuestion DATA QL 255.0 QL.1} 'FALSE'} {List.subtract QL {BestQuestion DATA QL 255.0 QL.1}}}
                        )
                     else
                        {BuildDecisionTree DATA {List.subtract QL {BestQuestion DATA QL 255.0 QL.1}}}
                     end
               else
                     {BuildDecisionTree DATA {List.subtract QL {BestQuestion DATA QL 255.0 QL.1}}}
               
               end
               
               
               
      end

      fun {TreeBuilder DATA}
         {BuildDecisionTree DATA {Record.arity DATABASE.1}.2}
      end

      proc {WriteListToFile L F}
	 		% Write L in the file F
         %L : data
         %F : a open file
            case L
            of H|nil then
               {F write(vs:H)}
            [] H|T then
               {F write(vs:H#",")}
               {WriteListToFile T F}
            else {WriteListToFile [L] F}    
            end

      end

      fun {GameDriver Tree}
         RESULT
         
      in
         if {Record.label Tree} \= 'leaf' then
            if {ProjectLib.askQuestion Tree.1} then
               RESULT = {GameDriver Tree.true}
            else
               RESULT = {GameDriver Tree.false}
            end
         else              
            RESULT = {ProjectLib.found Tree.1}
            if RESULT == false then
               {WriteListToFile {ProjectLib.surrender} OutputFile}
            else
               {WriteListToFile RESULT OutputFile} 
            end   
            
         end
         unit
      end
   in 
      {Browse {BuildDecisionTree DATABASE {Record.arity DATABASE.1}.2}}
      {ProjectLib.play opts(characters:DATABASE noGUI:NoGUI driver:GameDriver builder:TreeBuilder 
                            autoPlay:ListOfAnswers)} % newCharacter:NewCharacter)}
      {Application.exit 0}
   end  
end
