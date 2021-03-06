'use strict'

angular.module('app.task', [])

.value('config', {
    host: 'http://localhost:3333'
})

.factory('Task', [
    '$http', '$q', 'config'
    ($http, $q, config) ->
        return {
            getTodos: ->
                deferred = $q.defer()
                $http( method: 'GET', url: "#{config.host}/todo")
                    .success (data, status, headers, config) ->
                        deferred.resolve(data)
                    .error (data, status, headers, config) ->
                        deferred.reject(status)
                deferred.promise

            addTodo: (item)->
                deferred = $q.defer()
                $http( method: 'POST', url: "#{config.host}/todo", data: item)
                    .success (data, status, headers, config) ->
                        deferred.resolve(data)
                    .error (data, status, headers, config) ->
                        deferred.reject(status)
                deferred.promise                

            editTodo: (oldItemName, newItem)->
                deferred = $q.defer()

                $http( method: 'PUT', url: "#{config.host}/todo/#{oldItemName}", data: newItem)
                    .success (data, status, headers, config) ->
                        deferred.resolve(data)
                    .error (data, status, headers, config) ->
                        deferred.reject(status)
                deferred.promise                  

            markAll: (completed) ->
                data = {completed: completed}

                deferred = $q.defer()
                $http( method: 'PUT', url: "#{config.host}/todoAll", data: data)
                    .success (data, status, headers, config) ->
                        deferred.resolve(data)
                    .error ( data, status, headers, config ) ->
                        deferred.reject(status)
                deferred.promise 

            removeTodo: (item)->
                itemName = item.title
                deferred = $q.defer()

                $http( method: 'DELETE', url: "#{config.host}/todo/#{itemName}")
                    .success (data, status, headers, config) ->
                        deferred.resolve(data)
                    .error (data, status, headers, config) ->
                        deferred.reject(status)
                deferred.promise

            removeCompleted: ()->
                deferred = $q.defer()

                $http( method: 'DELETE', url: "#{config.host}/todoCompleted")
                    .success (data, status, headers, config) ->
                        deferred.resolve(data)
                    .error (data, status, headers, config) ->
                        deferred.reject(status)
                deferred.promise
        }
])

# cusor focus when dblclick to edit
.directive('taskFocus', [
    '$timeout'
    ($timeout) ->
        return {
            link: (scope, ele, attrs) ->
                scope.$watch(attrs.taskFocus, (newVal) ->
                    if newVal
                        $timeout( ->
                            ele[0].focus()
                        , 0, false)
                )
        }
])

.controller('taskCtrl', [
    '$scope', 'filterFilter', '$rootScope', 'Task'
    ($scope, filterFilter, $rootScope, Task) ->

        tasks = $scope.tasks = Task.getTodos().then(
            (data) ->
                $scope.tasks = data
                $scope.remainingCount = filterFilter($scope.tasks, {completed: false}).length
            (status) ->
                console.log status
        )

        $scope.newTask = ''
        $scope.editedTask = null
        $scope.statusFilter = {completed: false}

        $scope.filter = (filter) ->
            switch filter
                when 'all' then $scope.statusFilter = ''
                when 'active' then $scope.statusFilter = {completed: false}
                when 'completed' then $scope.statusFilter = {completed: true}

        $scope.add = ->
            newTask = $scope.newTask.trim()
            if newTask.length is 0
                return

            item =
                title: newTask
                completed: false

            Task.addTodo(item).then(
                (res) ->
                    $scope.tasks.push item
                    $scope.newTask = ''
                    $scope.remainingCount++
                (status) ->
                    conosole.log status
            )

        $scope.remove = (task) ->
            Task.removeTodo(task).then(
                (res) ->
                    $scope.remainingCount -= if task.completed then 0 else 1
                    index = $scope.tasks.indexOf(task)
                    $scope.tasks.splice(index, 1)
                (status) ->
                    console.log status
            )

        oldItem = undefined
        $scope.edit = (task)->
            oldItem = angular.copy(task)
            $scope.editedTask = task
        $scope.doneEditing = (task, $index) ->
            $scope.editedTask = null
            task.title = task.title.trim()

            if !task.title
                $scope.remove(task)

            Task.editTodo(oldItem.title, task).then(
                (res) ->
                (status) ->
                    console.log status
                    task.title = oldItem.title
            )

        $scope.completed = (task) ->
            Task.editTodo(task.title, task).then(
                (res) ->
                    $scope.remainingCount += if task.completed then -1 else 1
                (status) ->
                    console.log status
            )

        $scope.markAll = (completed)->
            Task.markAll(completed)
            $scope.tasks.forEach( (task) ->
                task.completed = completed
            )
            $scope.remainingCount = if completed then 0 else tasks.length

        $scope.clearCompleted = ->
            Task.removeCompleted()
            $scope.tasks = $scope.tasks.filter( (val) ->
                return !val.completed
            )

        $scope.$watch('remainingCount == 0', (val) ->
            $scope.allChecked = val
        )

        $scope.$watch('remainingCount', (newVal, oldVal) ->
            $rootScope.$broadcast('taskRemaining:changed', newVal) 
        )
])

