class window.Base1
    @classMethod: () ->
        return super() + "Base1"

    init: () ->
        return super() + "Base1"


class window.Base2
    @classMethod: () ->
        return "Base2"

    init: () ->
        return "Base2"


class window.Deriv extends heterarchy.multi Base1, Base2

    @classMethod: () ->
        return super() + "Deriv"

    init: () ->
        return super() + "Deriv"
