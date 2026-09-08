import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import luxonPlugin from "@fullcalendar/luxon3"
import ptBrLocale from "@fullcalendar/core/locales/pt-br"

export default class extends Controller {
  static targets = [
    "calendar", "history", "error", "dialog", "kind", "title", "time",
    "client", "clientRow", "service", "status", "statusRow", "reason",
    "reasonRow", "detailsLink", "editBlockLink"
  ]

  static values = {
    eventsUrl: String,
    businessHours: Array
  }

  connect() {
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [dayGridPlugin, timeGridPlugin, luxonPlugin],
      locale: ptBrLocale,
      timeZone: "America/Sao_Paulo",
      initialView: this.mobile ? "timeGridDay" : "timeGridWeek",
      headerToolbar: this.toolbar,
      buttonText: { today: "Hoje", month: "Mês", week: "Semana", day: "Dia" },
      businessHours: this.businessHoursValue,
      nowIndicator: true,
      allDayText: "Dia inteiro",
      slotMinTime: "06:00:00",
      slotMaxTime: "22:00:00",
      slotDuration: "00:30:00",
      height: "auto",
      navLinks: true,
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },
      events: {
        url: this.eventsUrlValue,
        extraParams: () => ({ include_history: this.historyTarget.checked })
      },
      eventClick: (info) => this.openEvent(info.event),
      eventSourceSuccess: () => this.errorTarget.classList.add("hidden"),
      eventSourceFailure: () => this.errorTarget.classList.remove("hidden"),
      windowResize: () => this.updateToolbar()
    })

    this.calendar.render()
  }

  disconnect() {
    this.calendar?.destroy()
  }

  toggleHistory() {
    this.calendar.refetchEvents()
  }

  retry() {
    this.errorTarget.classList.add("hidden")
    this.calendar.refetchEvents()
  }

  closeDialog() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.closeDialog()
  }

  openEvent(event) {
    const properties = event.extendedProps
    const appointment = properties.kind === "appointment"

    this.kindTarget.textContent = appointment ? "Agendamento" : "Bloqueio"
    this.titleTarget.textContent = event.title
    this.timeTarget.textContent = this.formatRange(event)
    this.serviceTarget.textContent = properties.serviceName || properties.scope

    this.clientRowTarget.classList.toggle("hidden", !appointment)
    this.statusRowTarget.classList.toggle("hidden", !appointment)
    this.reasonRowTarget.classList.toggle("hidden", appointment)
    this.detailsLinkTarget.classList.toggle("hidden", !appointment)
    const canEditBlock = !appointment && Boolean(properties.editUrl)
    this.editBlockLinkTarget.classList.toggle("hidden", !canEditBlock)
    this.editBlockLinkTarget.classList.toggle("inline-flex", canEditBlock)
    if (canEditBlock) this.editBlockLinkTarget.href = properties.editUrl
    else this.editBlockLinkTarget.removeAttribute("href")

    if (appointment) {
      this.clientTarget.textContent = properties.clientName
      this.statusTarget.textContent = properties.status
      this.detailsLinkTarget.href = properties.detailsUrl
    } else {
      this.reasonTarget.textContent = properties.reason
      this.detailsLinkTarget.removeAttribute("href")
    }

    this.dialogTarget.showModal()
  }

  formatRange(event) {
    const options = event.allDay
      ? { dateStyle: "full" }
      : { dateStyle: "short", timeStyle: "short" }
    const formatter = new Intl.DateTimeFormat("pt-BR", {
      ...options,
      timeZone: "America/Sao_Paulo"
    })

    if (event.allDay) return formatter.format(event.start)

    return `${formatter.format(event.start)} – ${formatter.format(event.end)}`
  }

  updateToolbar() {
    this.calendar.setOption("headerToolbar", this.toolbar)
  }

  get mobile() {
    return window.matchMedia("(max-width: 639px)").matches
  }

  get toolbar() {
    if (this.mobile) {
      return { start: "prev,next", center: "title", end: "today dayGridMonth,timeGridWeek,timeGridDay" }
    }

    return { start: "prev,next today", center: "title", end: "dayGridMonth,timeGridWeek,timeGridDay" }
  }
}
