pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell

Item {
    id: root

    property list<var> sections: [
        
    ]

    function registerSection(data) {
        sections.push(data)
    }

    function getBestResult(text) {
        let results = getSearchResult(text)
        if (results.length === 0)
            return null

        results.sort((a, b) => scoreResult(b, text) - scoreResult(a, text))
        return results[0]
    }

    function getResultsRanked(text) {
        let results = getSearchResult(text)
        if (results.length === 0)
            return null

        results.sort((a, b) => scoreResult(b, text) - scoreResult(a, text))
        return results
    }

    function getSearchResult(text) {
        var results = []
        text = text.toLowerCase()

        for (var i in root.sections) {
            var section = root.sections[i]
            for (var j in section.keywords) {
                var keyword = section.keywords[j].toLowerCase()
                var words = keyword.split(/\s+/) // keyword'u kelimelere ayır
                for (var k in words) {
                    if (words[k].includes(text)) {
                        results.push({
                            pageIndex: section.pageIndex,
                            title: section.title,
                            keyword: words[k], // eşleşen kelimeyi kaydet
                            yPos: section.yPos
                        })
                        break // bir keyword içindeki kelimelerden biri eşleşince diğerlerine bakmaya gerek yok
                    }
                }
            }
        }
        return results
    }


    function scoreResult(result, text) {
        let keyword = result.keyword
        text = text.toLowerCase()

        if (keyword === text) return 1000
        if (keyword.startsWith(text)) return 700
        if (keyword.includes(text)) return 400

        return 200 - keyword.length
    }




    

}