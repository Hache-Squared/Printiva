namespace ManejoPresupuestos.Models
{
    public class PedidoAccionDisponible
    {
        public string AccionCodigo { get; set; } = "";
        public string AccionTexto { get; set; } = "";
        public int HaciaEstatusId { get; set; }
        public bool RequiereConfirmacion { get; set; }
        public bool Bloqueada { get; set; }
        public string Motivo { get; set; } = "";
    }
}
