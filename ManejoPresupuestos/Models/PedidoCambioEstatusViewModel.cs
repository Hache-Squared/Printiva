using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class PedidoCambioEstatusViewModel
    {
        public int PedidoId { get; set; }

        [Required]
        public int HaciaEstatusId { get; set; }

        [StringLength(500)]
        public string? Notas { get; set; }
    }
}
