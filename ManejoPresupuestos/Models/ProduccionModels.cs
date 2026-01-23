namespace ManejoPresupuestos.Models
{
    public class ProduccionEstatus
    {
        public int ProduccionEstatusId { get; set; }
        public string Nombre { get; set; } = "";
        public int Orden { get; set; }
        public string BadgeClass { get; set; } = "bg-secondary";
    }

    public class ProduccionItemRow
    {
        public int ProduccionItemId { get; set; }
        public int PedidoId { get; set; }
        public int PedidoItemId { get; set; }
        public int ProductoId { get; set; }
        public string ProductoNombre { get; set; } = "";
        public int Cantidad { get; set; }

        public int ProduccionEstatusId { get; set; }
        public string EstatusNombre { get; set; } = "";
        public string BadgeClass { get; set; } = "bg-secondary";

        public string? Notas { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaActualizacion { get; set; }
    }

    public class ProduccionAccionDisponible
    {
        public string AccionCodigo { get; set; } = "";
        public string AccionTexto { get; set; } = "";
        public int HaciaEstatusId { get; set; }
        public bool RequiereConfirmacion { get; set; }
        public bool Bloqueada { get; set; }
        public string Motivo { get; set; } = "";
    }

    public class ProduccionCambiarEstatusViewModel
    {
        public int ProduccionItemId { get; set; }
        public int HaciaEstatusId { get; set; }
        public string? Notas { get; set; }
    }

    public class ProduccionPedidoViewModel
    {
        public Pedido Pedido { get; set; } = new Pedido();
        public IEnumerable<ProduccionItemRow> Items { get; set; } = Enumerable.Empty<ProduccionItemRow>();
        public IEnumerable<ProduccionEstatus> Estatus { get; set; } = Enumerable.Empty<ProduccionEstatus>();
    }
}
