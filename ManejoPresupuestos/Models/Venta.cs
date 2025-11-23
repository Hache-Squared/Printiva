using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class Venta
    {
        public int VentaId { get; set; }

        [Display(Name = "Cliente")]
        public int? ClienteId { get; set; }

        public string Descripcion { get; set; }

        [Display(Name = "Costo total")]
        public decimal CostoTotal { get; set; }

        [Display(Name = "Fecha")]
        [DataType(DataType.Date)]
        public DateTime FechaCreacion { get; set; } = DateTime.Today;

        public int UsuarioId { get; set; } // By default, current user

        public string ClienteNombre { get; set; } = string.Empty;
    }
}
